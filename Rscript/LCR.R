# ripulisci tutto
rm(list = ls())

file_path <- file.choose()

# leggi il file dei dati
data <- read.table(file_path, header = TRUE, sep = "\t")

# estrai i nomi dei gruppi dalla seconda riga del file
group_names <- scan(file_path, what = "", skip = 1, nlines = 1, sep = "\t")

# stampa i nomi dei gruppi
groups <- unique(group_names[-1])
# cat("I nomi dei gruppi sono:", paste(groups, collapse = ", "))
cat("I nomi dei gruppi sono:", paste(groups, collapse = ", "), "\n")

#-----------------------------------
#imposta le variabili

messaggio <- "Inserisci un valore per il p-value: "
limite_P <- readline(messaggio)

messaggio <- "Inserisci il nome del gruppo Controllo: "
Control_group <- readline(messaggio)

messaggio <- "Inserisci il nome del gruppo esperimento: "
Experimental_group <- readline(messaggio)

#----------------------------------------

# aggiunge una numerazione crescente separata da "_"
new_group_names <- paste0(group_names, "_", seq_along(group_names))

#sostituisce l'intestazione di data con new_group_names
names(data) <- new_group_names
# Rimuovere la prima riga da data
data <- data[-1, ]

# Impostare la prima colonna come rownames
rownames(data) <- data[,1]
data[,1] <- NULL

# crea i vettori per ogni variabile e classe
for (i in 1:nrow(data)) {
  var_name <- rownames(data)[i]
  class_names <- unique(sub("_.*", "", colnames(data)[-1]))
  for (class_name in class_names) {
    class_vec <- data[i, grep(paste0(class_name, "_"), colnames(data))]
    # converti i valori del vettore in numeri
    class_vec <- as.numeric(class_vec)
    assign(paste(var_name, class_name, sep = "_"), class_vec)
  }
}

# carica la tabella
reazioni <- read.table("reazioni.txt", header = TRUE, sep = "\t")

# aggiunge tre colonne "P.value", "Z-score" e t-student
reazioni$P.value <- NA
reazioni$Z.score <- NA
reazioni$t.student <- NA

# ciclo su ogni riga della tabella
for (i in 1:nrow(reazioni)) {
  # estrae il nome delle variabili e della classe
  var1 <- gsub("_.*", "", reazioni[i, "variabile_1"])
  var2 <- gsub("_.*", "", reazioni[i, "variabile_2"])
  classe <- gsub(".*_", "", reazioni[i, "variabile_1"])
  
  # controlla se esistono i vettori "var1_CTRL" e "var2_CTRL" e "var1_F2" e "var2_F2"
  if (exists(paste0(var1, "_", Control_group)) && exists(paste0(var2, "_", Control_group)) &&
      exists(paste0(var1, "_", Experimental_group)) && exists(paste0(var2, "_",Experimental_group))) {
    
    # controlla che i valori dei vettori siano numerici
    if (is.numeric(get(paste0(var1, "_", Control_group))) && is.numeric(get(paste0(var2, "_", Control_group))) && 
        is.numeric(get(paste0(var1, "_", Experimental_group))) && is.numeric(get(paste0(var2, "_",Experimental_group)))) {
      
      # calcola i vettori ctrl ed exp
      ctrl <- get(paste0(var2, "_", Control_group)) / get(paste0(var1, "_", Control_group))
      exp <- get(paste0(var2, "_", Experimental_group)) / get(paste0(var1, "_", Experimental_group))
      
      # esegue il t.test
      result <- t.test(ctrl, exp, var.equal = TRUE)
      
      # riporta il valore p.value e lo Z-score nella tabella
      reazioni[i, "t.student"] <- result$statistic
      reazioni[i, "P.value"] <- result$p.value
      reazioni[i, "Z.score"] <- abs(qnorm(result$p.value))
    }
  }
}


# Seleziona solo le righe con P.value numerico
reazioni2 <- reazioni[!is.na(as.numeric(reazioni$P.value)),]

# Seleziona solo le righe con P.value < limite_P
reazioni2 <- reazioni2[as.numeric(reazioni2$P.value) < limite_P,]

# arrotonda il valore Z.score alla prima cifra decimale
reazioni2$Z.score <- round(reazioni2$Z.score, 1)


# carico la libreria igraph
library(igraph)

# creo il grafo orientato
g <- graph_from_data_frame(reazioni2, directed = TRUE)

# imposto i nomi dei nodi
V(g)$label <- V(g)$name

# imposto i nomi degli archi
E(g)$label <- paste(E(g)$GENE, "(", E(g)$Z.score, ")", sep = "")

# aggiungo l'attributo "color" agli archi del grafo in base al valore di t.student
E(g)$color <- ifelse(reazioni2$t.student < 0, "red", "blue")

# imposto i colori degli archi orientati
# E(g)$color[E(g)$to > E(g)$from] <- "black"
# E(g)$color[E(g)$to < E(g)$from] <- "red"
# E(g)$color <- ifelse(E(g)$P.value < limite_P, ifelse(E(g)$Z.score > 1.64, "black", "red"), "gray")

#----------------------
# disegno il grafo
# plot(g, layout = layout.circle, vertex.label.cex = 0.7, vertex.size = 25, vertex.label.dist = 1.5)
#-----------------------------------


# disegno il grafo
plot(g,
     vertex.shape = "circle",
     vertex.size = 25,
     vertex.label.family = "sans",
     vertex.label.cex = 0.9,
     edge.label = E(g)$label,
     edge.label.family = "sans",
     edge.label.cex = 0.8,
     edge.curved = 0.5,
     edge.arrow.size = 0.9,
     edge.color = E(g)$color,
     layout = layout_as_tree)