#*************************************************
# questo script quantifica una tabella lipidi in cui la prima colonna si chiama "Metabolite" e contiene i nomi dei lipidi, il resto delle colonne conengono solo dati numerici, e nella prima riga il nome dei campioni
# per funzionare è necessaria la tabella "standard.txt" formata da tre colonne: Standard, Class, Conc che riporta rispettivamente lo standard, la classe (prima parte del nome fino allo spazio, e la concentrazione dello standard
#*************************************************
# ripulisci tutto
rm(list = ls())

# leggi il file dei dati e ordina per la prima colonna
data_path <- file.choose()
data <- read.table(data_path, header = TRUE, sep = "\t")
# data <- data[order(data[,1]),]

# leggi il file degli standard e ordina per la prima colonna
standard <- as.data.frame(read.table("standard.txt", header = TRUE, sep = "\t"))
#standard <- standard[order(standard[,1]),]

# estrae i nomi degli standard dalla tabella "standard"
standard_names <- unique(standard$Standard)

# 1) individua gli standard nella tabella "data"
standard_names <- unique(standard$Standard)
data_standard <- data[data[,1] %in% standard_names,]

# 2) individua il corrispondente standard per ogni metabolita di "data"
data$standard <- NA
for (i in 1:nrow(data)) {
  metabolite_name <- unlist(strsplit(as.character(data[i, 1]), split=" "))[1]
  corresponding_standard <- standard[standard$Class == metabolite_name, "Standard"]
  if (length(corresponding_standard) > 0) {
    data$standard[i] <- corresponding_standard
  }
}

# sposta la colonna "standard" come seconda colonna di "data"
data <- cbind(data[,1], data[,ncol(data)], data[,2:(ncol(data)-1)])

# rinomina la colonna "Metabolite"
colnames(data)[1] <- "Metabolite"

# rinomina la colonna "used_standard"
colnames(data)[2] <- "used_standard"

# salva la colonna Metabolite in una variabile separata
Metabolite_col <- data$Metabolite

# Rimuovi la colonna "Metabolite" da "data" e salvala in una nuova variabile
metabolite <- data[,1]
data <- data[, -1]

library(dplyr)
data_standard <- data_standard %>% rename(used_standard = Metabolite)

#------------------------------------------
CONC <- standard$Conc[match(data$used_standard, standard$Standard)]


# crea una copia di "data" chiamata "risultati_mul"
risultati_mul <- data

# sostituisci le colonne di "risultati_mul" tranne la prima con i valori moltiplicati
for (i in 2:ncol(risultati_mul)) {
  risultati_mul[,i] <- risultati_mul[,i] * CONC
}

 data <- risultati_mul
#--------------------------------------------

# Crea il dataframe "risultato" con la stessa struttura di "data"
risultato <- data.frame(matrix(0, nrow=nrow(data), ncol=ncol(data)))

# Aggiungi i nomi delle colonne a "risultato"
colnames(risultato) <- colnames(data)

# Itera su ogni riga di "data"
for (i in 1:nrow(data)) {
  # Estrai il nome dell'elemento nella prima colonna di "data"
  metabolite_name <- gsub("\\s+$", "", as.character(data[i, 1]))
  
  # Cerca l'elemento corrispondente nella prima colonna di "data_standard"
  corresponding_standard <- data_standard[data_standard[, 1] == metabolite_name, ]
  
  # Se c'è una corrispondenza, calcola il rapporto tra le due righe
  if (nrow(corresponding_standard) > 0) {
    ratio <- data[i, 2:ncol(data)] / corresponding_standard[, 2:ncol(data_standard)]
    risultato[i, 1] <- metabolite_name
    risultato[i, 2:ncol(risultato)] <- ratio
  }
}

# Aggiungi il nome della colonna "standard" a "risultato"
risultato <- cbind(Metabolite_col, risultato)

# Rinomina la colonna "Metabolite" di "risultato"
colnames(risultato)[1] <- "Metabolite"
risultato[1] <- Metabolite_col
risultato <- subset(risultato, select = -c(2))

# ottieni il nome del file di input senza l'estensione
filename <- basename(data_path)
filename <- substr(filename, 1, nchar(filename) - nchar(".txt"))

# crea il nome del file di output con l'aggiunta di "_Quant"
output_filename <- paste0(filename, "_Quant.txt")

# salva i dati di "risultato" nel file di output
write.table(risultato, file = output_filename, sep = "\t", row.names = FALSE)

