log.file<-file(snakemake@log[[1]],open="wt")
sink(log.file)
sink(log.file,type="message")

library(dada2)

sam.names= sort(snakemake@params[["samples"]])
filtFs = sort(snakemake@input[['R1']])
filtRs = sort(snakemake@input[['R2']])

errF <- readRDS(snakemake@input[['errR1']])
errR <- readRDS(snakemake@input[['errR2']]) #errR

# derep - merge
mergers <- vector("list", length(sam.names))
dadaFs <- vector("list", length(sam.names))
names(mergers) <- sam.names
names(dadaFs) <- sam.names

names(filtFs) <- sam.names
names(filtRs) <- sam.names

for(sam in sam.names) {
  cat("Processing:", sam, "\n")

  derepF <- derepFastq(filtFs[[sam]])
  ddF <- dada(derepF, err=errF)

  dadaFs[[sam]] <- ddF
  derepR <- derepFastq(filtRs[[sam]])
  ddR <- dada(derepR, err=errR)

  merger <- mergePairs(ddF, derepF, ddR, derepR)
  mergers[[sam]] <- merger
}

## ---- seqtab ----
seqtab.all <- makeSequenceTable(mergers)

## ---- save seqtab ----

saveRDS(seqtab.all, snakemake@output[['seqtab']])
# Proper syntax to close the connection for the log file
# but could be optional for Snakemake wrapper
sink(type="message")
sink()
