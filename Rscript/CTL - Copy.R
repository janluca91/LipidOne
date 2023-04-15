# prende una matrice dati di lipidi in forma MetaboAnalyst (DataMatrixEsempio.txt), separa i nomi dei lipidi in colonne separate come LipidClass e chains, inoltre crea le classi degli eteri ad esempio PC-O oppure PE-P
# Attualmente crea la LipidClassMatrix.txt che è una matrice classi lipidiche (tipo tabella pivot delle specie molecolari lipidiche)




# ripulisci tutto
rm(list = ls())

file_path <- file.choose()

# leggi il file dei dati
dati <- read.table(file_path, header = TRUE, sep = "\t")


# estrai il nome del file
nome_file <- basename(file_path)

# Crea un nuovo dataframe con la prima colonna di 'dati'
lipidi_df <- data.frame(lipidi = dati[,1])

# Divide la colonna 'lipidi' in due parti delimitate da uno spazio
lipidi_df <- data.frame(do.call("rbind", strsplit(lipidi_df$lipidi, " ")))

# Aggiunge una colonna vuota chiamata col3
lipidi_df$col3 <- ""

# Aggiorna col3 in base alla presenza di 'O-' o 'P-' in X2
lipidi_df$col3 <- ifelse(grepl("^O-", lipidi_df$X2), paste0(lipidi_df$X1, "-O"), 
                         ifelse(grepl("^P-", lipidi_df$X2), paste0(lipidi_df$X1, "-P"), lipidi_df$X1))

new_df <- data.frame(paste(lipidi_df$col3, lipidi_df$X2, sep = " "))

dati <- cbind(subset(new_df), dati[, -1])
names(dati)[1] <- "File"


# Crea un nuovo data frame con le colonne vuote
nuovi_dati <- data.frame(File=dati$File, LipidClass=rep("", nrow(dati)), 
                          Chain1=rep("", nrow(dati)), Chain2=rep("", nrow(dati)),
                          Chain3=rep("", nrow(dati)), Chain4=rep("", nrow(dati)))

# Estrai la classe lipidica e le catene per ogni lipide e riempi le colonne del nuovo data frame
for (i in 2:nrow(dati)) {
  lipide <- strsplit(as.character(dati$File[i]), " ")[[1]]
  nuovi_dati$LipidClass[i] <- lipide[1]
  catene <- strsplit(lipide[2], "_")[[1]]
  for (j in 1:length(catene)) {
    nuovi_dati[[paste0("Chain", j)]][i] <- catene[j]
  }
}

dati <- cbind(dati, Value=rep("", nrow(dati)))
dati <- dati[, -ncol(dati)]
dati[1, 1]<-"label"

# fonde le due tabelle
merged_data <- merge(nuovi_dati,dati, sort = FALSE, by = "File")
#--------------------------------------------------------------
# IN QUESTA SEZIONE SI RICAVA LA MATRICE DATI "CLASSI LIPIDICHE"
#--------------------------------------------------------------
# crea un nuovo dataframe utilizzando la seconda colonna (classe lipidica) e dalla settima colonna in poi

nuovo_df <- merged_data[, c(2, 7:ncol(merged_data))]

# Stacca le prime due righe e salva come vettori
vet1 <- as.vector(nuovo_df[1, -1])
vet2 <- as.vector(nuovo_df[2, -1])

# Seleziona solo le colonne numeriche dal tuo dataframe
colonne_numeriche <- sapply(nuovo_df, is.numeric)

# Converti le colonne numeriche in tipo numerico
nuovo_df[, colonne_numeriche] <- lapply(nuovo_df[, colonne_numeriche], as.numeric)

# Seleziona tutte le righe dalla terza in poi e somma per nome
dati_tail <- nuovo_df[-c(1, 2), ]

# crea un nuovo dataframe vuoto
nuovo_dati_tail <- data.frame()

# ottieni i nomi delle classi di lipidi
classi_lipidi <- unique(dati_tail$LipidClass)

# per ogni classe di lipidi, somma le righe corrispondenti
#for (classe in classi_lipidi) {
  #righe_classe <- dati_tail[dati_tail$LipidClass == classe, ]
  #somma_righe <- colSums(sapply(righe_classe[, -1], as.numeric))
  #nuovo_riga <- c(classe, somma_righe)
  #nuovo_dati_tail <- rbind(nuovo_dati_tail, nuovo_riga)
#}
#---------------------
# inizializza il nuovo dataset
nuovo_dati_tail <- NULL

# per ogni classe di lipidi, somma le righe corrispondenti
for (classe in unique(dati_tail$LipidClass)) {
  righe_classe <- dati_tail[dati_tail$LipidClass == classe, ]
  
  if (nrow(righe_classe) == 1) {
    nuovo_riga <- as.vector(righe_classe)
  } else {
    somma_righe <- colSums(sapply(righe_classe[, -1], as.numeric))
    nuovo_riga <- c(classe, somma_righe)
  }
  
  nuovo_dati_tail <- rbind(nuovo_dati_tail, nuovo_riga)
}


#---------------------
# imposta i nomi delle colonne e delle righe del nuovo dataframe
colnames(nuovo_dati_tail) <- colnames(dati_tail)
rownames(nuovo_dati_tail) <- classi_lipidi

# Copia della seconda riga del dataframe "dati"
seconda_riga <- dati[1,]

colnames(seconda_riga) <- colnames(nuovo_dati_tail)

# Inserimento della seconda riga nel dataframe "novo_dati_tail"
nuovo_dati_tail <- rbind(nuovo_dati_tail[0,], seconda_riga, nuovo_dati_tail[1,],nuovo_dati_tail[-1,])

# converte la lista in un data frame
nuovo_dati_tail_df <- as.data.frame(nuovo_dati_tail)

# converte le colonne di tipo "list" in caratteri o numeri
for (i in 1:ncol(nuovo_dati_tail_df)) {
  if (is.list(nuovo_dati_tail_df[[i]])) {
    nuovo_dati_tail_df[[i]] <- unlist(nuovo_dati_tail_df[[i]])
    if (all(sapply(nuovo_dati_tail_df[[i]], is.numeric))) {
      nuovo_dati_tail_df[[i]] <- as.numeric(nuovo_dati_tail_df[[i]])
    } else {
      nuovo_dati_tail_df[[i]] <- as.character(nuovo_dati_tail_df[[i]])
    }
  }
}

# crea la stringa di testo da utilizzare per il file di output
testo <- paste0("LipidClass_", nome_file)

# salva il data frame in un file di testo
write.table(nuovo_dati_tail_df, testo, sep = "\t", row.names = FALSE)


