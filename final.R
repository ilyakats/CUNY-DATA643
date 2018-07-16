# ----------------------------- READING AWS S3 DATA INTO R -----------------------------

install.packages("aws.s3")

library(aws.s3)

Sys.setenv("AWS_ACCESS_KEY_ID" = "AKIAJUGWG3SNEZGRRDTA",
           "AWS_SECRET_ACCESS_KEY" = "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",
           "AWS_DEFAULT_REGION" = "us-east-1")

# List S3 buckets
bucketlist()

# Small file from my project 5 for testing
obj <- get_object("ratings_Beauty_Short.csv", bucket = "data643summer18")
beauty <- read.csv(text = rawToChar(obj))

# Current csv file for video games
obj <- get_object("ratings_Video_Games.csv", bucket = "data643summer18")
games <- read.csv(text = rawToChar(obj))


# ----------------------------- READING AWS S3 DATA INTO SPARK -----------------------------

library(sparklyr)
library(dplyr)

config <- spark_config()
config$`spark.hadoop.fs.s3a.impl` <- "org.apache.hadoop.fs.s3a.S3AFileSystem"
config$`fs.s3a.access.key` <- "AKIAJUGWG3SNEZGRRDTA"
config$`fs.s3a.secret.key` <- "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"

sc <- spark_connect(master = "local", config = config)

beauty_tbl <- spark_read_csv(sc, name = "beauty_ratings", path = "s3a://data643summer18/ratings_Beauty_Short.csv")

spark_disconnect(sc)


#Get spark context 
ctx <- spark_context(sc)
#Use below to set the java spark context 
jsc <- invoke_static(sc, "org.apache.spark.api.java.JavaSparkContext", "fromSparkContext", ctx)

#set the s3 configs: 
hconf <- jsc %>% invoke("hadoopConfiguration")
hconf %>% invoke("set","spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
hconf %>% invoke("set","fs.s3a.access.key", "AKIAJUGWG3SNEZGRRDTA")
hconf %>% invoke("set","fs.s3a.secret.key", "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")

usercsv_tbl <- spark_read_csv(sc, name = "beautytbl",path = "s3a://data643summer18/ratings_Beauty_Short.csv")

library(tidyverse)
library(sparklyr)



config$`sparklyr.shell.driver-java-options` <- paste0("-Djava.io.tmpdir=", 
                                                      spark_home_dir())
config$`sparklyr.shell.driver-memory` <- "4G"
config$`sparklyr.shell.executor-memory` <- "4G"
config$`spark.yarn.executor.memoryOverhead` <- "512"
sc <- spark_connect(master = "local", config = config, version = '2.3.0')

rvw5 <- spark_read_json(sc, name = "five_reviews",
                        header = TRUE, 
                        path = "Video_Games_5.json")



Sys.getenv("SPARK_HOME")
Sys.setenv(SPARK_HOME="C:/Users/ikats/AppData/Local/spark/spark-2.1.0-bin-hadoop2.7/bin")
sc <- spark_connect(master = "spark://54.173.106.94", version="2.1.0")
connection_is_open(sc)
spark_disconnect(sc)



livy_install()
