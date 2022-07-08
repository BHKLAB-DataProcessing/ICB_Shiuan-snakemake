library(data.table)

args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_dir <- args[2]

source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/Get_Response.R")
source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/format_clin_data.R")

#############################################################################
#############################################################################

expr = as.matrix( read.table( file.path(input_dir, "EXPR.txt") , sep="\t" , header=TRUE , stringsAsFactors = FALSE , dec = "," ) )
rownames(expr) = sapply( expr[ , 1 ] , function( x ){ unlist( strsplit( x , "|" , fixed = TRUE ))[1] } ) 
colnames(expr) = sapply( colnames( expr ) , function( x ){ paste( "P" , unlist( strsplit( x , "X" , fixed = TRUE ))[2] , sep = "" ) } ) 
expr = expr[ , -1 ]

cid = colnames( expr )
expr = log2( t( apply( expr , 1 , as.numeric ) ) + 1 )
colnames(expr) = cid

#############################################################################
#############################################################################
## Remove duplicate genes

expr_uniq <- expr[!(rownames(expr)%in%rownames(expr[duplicated(rownames(expr)),])),]
expr_dup <- expr[(rownames(expr)%in%rownames(expr[duplicated(rownames(expr)),])),]

expr_dup <- expr_dup[order(rownames(expr_dup)),]
id <- unique(rownames(expr_dup))

expr_dup.rm <- NULL
names <- NULL
for(j in 1:length(id)){
	expr <- expr_dup[which(rownames(expr_dup)%in%id[j]),]
	tmp.sum <- apply(expr,1,function(x){ mean( as.numeric(as.character(x)),na.rm=T ) } )
	expr <- expr[which(tmp.sum%in%max(tmp.sum,na.rm=T)),]

	if( is.null(dim(expr)) ){
	  expr_dup.rm <- rbind(expr_dup.rm,expr) 
	  names <- c(names,names(tmp.sum)[1])
	}   
}
expr <- rbind(expr_uniq,expr_dup.rm)
rownames(expr) <- c(rownames(expr_uniq),names)
tpm = expr[sort(rownames(expr)),]


#############################################################################
#############################################################################
## Get Clinical data

clin = read.table( file.path(input_dir, "CLIN.txt") , sep="\t" , header=TRUE , stringsAsFactors = FALSE )
clin[ , 1 ] = paste( "P" , clin[ , 1 ] , sep = "" )
rownames(clin) = clin[ , 1 ] 

clin_original <- clin
selected_cols <- c('Study.ID', 'ICI.best.response')
clin = as.data.frame( cbind( clin[ , selected_cols ] , "PD-1/PD-L1" , "Kidney" , NA , NA , NA , NA , NA , NA , NA , NA , NA , NA , NA , NA , NA ) )
colnames(clin) = c( "patient" , "recist" , "drug_type" , "primary" , "recist" , "age" , "histo" , "response" , "pfs" ,"os" , "t.pfs" , "t.os" , "stage" , "sex" , "response.other.info" , "dna" , "rna" )

clin$response = Get_Response( data=clin )
clin$rna = "tpm"
clin = clin[ , c("patient" , "sex" , "age" , "primary" , "histo" , "stage" , "response.other.info" , "recist" , "response" , "drug_type" , "dna" , "rna" , "t.pfs" , "pfs" , "t.os" , "os" ) ]

clin <- format_clin_data(clin_original, 'Study.ID', selected_cols, clin)

#############################################################################
#############################################################################

patient = intersect( colnames(expr) , rownames(clin) )
clin = clin[ patient , ]
expr =  expr[ , patient ]

case = cbind( patient , 0 , 0 , 1 )
colnames(case ) = c( "patient" , "snv" , "cna" , "expr" )

write.table( case , file = file.path(output_dir, "cased_sequenced.csv") , sep = ";" , quote = FALSE , row.names = FALSE)
write.table( clin , file = file.path(output_dir, "CLIN.csv") , sep = ";" , quote = FALSE , row.names = FALSE)
write.table( expr , file= file.path(output_dir, "EXPR.csv") , quote=FALSE , sep=";" , col.names=TRUE , row.names=TRUE )
