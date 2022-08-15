from snakemake.remote.S3 import RemoteProvider as S3RemoteProvider
S3 = S3RemoteProvider(
    access_key_id=config["key"], 
    secret_access_key=config["secret"],
    host=config["host"],
    stay_on_remote=False
)
prefix = config["prefix"]
filename = config["filename"]
data_source  = "https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Shiuan-data/main/"

rule get_MultiAssayExp:
    input:
        S3.remote(prefix + "processed/EXPR.csv"),
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "processed/CLIN.csv"),
        S3.remote(prefix + "annotation/Gencode.v40.annotation.RData")
    output:
        S3.remote(prefix + filename)
    resources:
        mem_mb=4000
    shell:
        """
        Rscript -e \
        '
        load(paste0("{prefix}", "annotation/Gencode.v40.annotation.RData"))
        source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/get_MultiAssayExp.R");
        saveRDS(
            get_MultiAssayExp(study = "Shiuan", input_dir = paste0("{prefix}", "processed")), 
            "{prefix}{filename}"
        );
        '
        """

rule download_annotation:
    output:
        S3.remote(prefix + "annotation/Gencode.v40.annotation.RData"),
        S3.remote(prefix + "annotation/curation_drug.csv"),
        S3.remote(prefix + "annotation/curation_tissue.csv")
    shell:
        """
        wget https://github.com/BHKLAB-Pachyderm/Annotations/blob/master/Gencode.v40.annotation.RData?raw=true -O {prefix}annotation/Gencode.v40.annotation.RData
        wget https://github.com/BHKLAB-Pachyderm/ICB_Common/raw/main/data/curation_drug.csv -O {prefix}annotation/curation_drug.csv
        wget https://github.com/BHKLAB-Pachyderm/ICB_Common/raw/main/data/curation_tissue.csv -O {prefix}annotation/curation_tissue.csv 
        """

rule format_data:
    input:
        S3.remote(prefix + "download/CLIN.txt"),
        S3.remote(prefix + "download/EXPR.txt"),
        S3.remote(prefix + "annotation/curation_drug.csv"),
        S3.remote(prefix + "annotation/curation_tissue.csv")
    output:
        S3.remote(prefix + "processed/EXPR.csv"),
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "processed/CLIN.csv")
    resources:
        mem_mb=2000
    shell:
        """
        Rscript scripts/Format_Data.R \
        {prefix}download \
        {prefix}processed \
        {prefix}annotation
        """

rule format_downloaded_data:
    input:
        S3.remote(prefix + "download/cancers-13-01475-s001.zip")
    output:
        S3.remote(prefix + "download/CLIN.txt"),
        S3.remote(prefix + "download/EXPR.txt")
    shell:
        """
        Rscript scripts/format_downloaded_data.R {prefix}download       
        """

rule download_data:
    output:
        S3.remote(prefix + "download/cancers-13-01475-s001.zip")
    resources:
        mem_mb=2000
    shell:
        """
        wget {data_source}cancers-13-01475-s001.zip -O {prefix}download/cancers-13-01475-s001.zip
        """ 