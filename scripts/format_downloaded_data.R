library(data.table)
library(readxl) 
library(stringr)

args <- commandArgs(trailingOnly = TRUE)
work_dir <- args[1]

unzip(file.path(work_dir, 'cancers-13-01475-s001.zip'), exdir=file.path(work_dir))

# CLIN.txt
clin <- read_excel(
  file.path(work_dir, '031421 Supplemental Data Tables S6-10.xlsx'), 
  sheet='Clinical labs'
)
colnames(clin) <- clin[2, ]
clin <- clin[-c(1:2), ]

mIF <- read_excel(
  file.path(work_dir, '031421 Supplemental Data Tables S6-10.xlsx'), 
  sheet='mIF'
)
colnames(mIF) <- mIF[2, ]
mIF <- mIF[-c(1:2), ]

colnames(clin) <- str_replace_all(colnames(clin), '\\W', '.')
colnames(mIF) <- str_replace_all(colnames(mIF), '\\W', '.')

added <- data.frame(matrix(ncol = length(colnames(mIF)), nrow = length(rownames(clin))))
colnames(added) <- colnames(mIF)
added$Sample.ID <- clin$Study.ID

for(col_name in colnames(added)){
  if(col_name != 'Sample.ID'){
    added[col_name] <- unlist(lapply(added$Sample.ID, function(sample){
      if(sample %in% mIF$Sample.ID){
        return(mIF[mIF$Sample.ID == sample, col_name])
      }else{
        return(NA)
      }
    }))
  }
}

clin <- cbind(clin, added)
clin$Sample.ID <- NULL
selected_cols <- c("Study.ID", "ICI.best.response", "PFS..days.", "PFS..months.")
clin <- clin[, c(selected_cols, colnames(clin)[!colnames(clin) %in% selected_cols])]
write.table( clin , file=file.path(work_dir, 'CLIN.txt') , quote=FALSE , sep="\t" , col.names=TRUE , row.names=FALSE )

# EXPR.txt
expr <- read_excel(
  file.path(work_dir, '031421 Supplemental Data Tables S6-10.xlsx'), 
  sheet='RNA-seq'
)
expr[2, 1] <- 'geneID'
colnames(expr) <- expr[2, ]
colnames(expr)[colnames(expr) != 'geneID'] <- paste0('X', colnames(expr)[colnames(expr) != 'geneID'])
expr <- expr[-c(1:2), ]
write.table( expr , file=file.path(work_dir, 'EXPR.txt') , quote=FALSE , sep="\t" , col.names=TRUE , row.names=FALSE )

file.remove(file.path(work_dir, '031421 Supplemental Data Tables S6-10.xlsx'))
file.remove(file.path(work_dir, '031421 Supplemental Figures and Tables S1-5.pdf'))
