install.packages("sparklyr")
install.packages("tictoc")


library(tictoc)
timing <- data.frame(Process=character(), Time=double())

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
tic()
obj <- get_object("ratings_Video_Games.csv", bucket = "data643summer18")
games <- read.csv(text = rawToChar(obj), header = FALSE)
colnames(games) <- c("UserID", "ProductID", "Rating", "TimeStamp")
t <- toc(quiet = TRUE)
timing <- rbind(timing, data.frame(Process = "Load Data from S3 into Local Data Frame", Time = round(t$toc - t$tic, 2)))

rm(obj)

class(games)
dim(games)
head(games)
length(unique(games$UserID))
length(unique(games$ProductID))

# ----------------------------- MOVING DATA INTO SPARK -----------------------------

library(sparklyr)
library(dplyr)

# LOCAL CONNECTION
tic()
config <- spark_config()
config$spark.executor.memory <- "2GB"
config$spark.memory.fraction <- 0.9
#config$`spark.hadoop.fs.s3a.impl` <- "org.apache.hadoop.fs.s3a.S3AFileSystem"
#config$`fs.s3a.access.key` <- "AKIAJUGWG3SNEZGRRDTA"
#config$`fs.s3a.secret.key` <- "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"
sc <- spark_connect(master = "local", config = config)
t <- toc(quiet = TRUE)
timing <- rbind(timing, data.frame(Process = "Establish Spark Connection", Time = round(t$toc - t$tic, 2)))

# SERVER CONNECTION
tic()
config <- spark_config()
#config$spark.executor.cores <- 2
#config$spark.dynamicAllocation.enabled <- "false"
config$spark.executor.memory <- "2GB"
config$spark.memory.fraction <- 0.9
#config$spark.driver.extraJavaOptions <- "-Dcom.amazonaws.services.s3.enableV4"
sc <- spark_connect(master="spark://ip-172-31-41-22.ec2.internal:7077", 
                    version = "2.1.0",
                    config = config,
                    spark_home = "/home/ubuntu/spark-2.1.0-bin-hadoop2.7/")
t <- toc(quiet = TRUE)
timing <- rbind(timing, data.frame(Process = "Establish Spark Connection", Time = round(t$toc - t$tic, 2)))

# Reading data directly from S3 into Spark is not working
ctx <- spark_context(sc)
jsc <- invoke_static(sc, "org.apache.spark.api.java.JavaSparkContext", "fromSparkContext", ctx)
hconf <- jsc %>% invoke("hadoopConfiguration")
hconf %>% invoke("set","fs.s3a.access.key", "AKIAJUGWG3SNEZGRRDTA")
hconf %>% invoke("set","fs.s3a.secret.key", "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")
games <- spark_read_csv(sc, name = "games_df", 
                        path = "s3a://data643summer18/ratings_Video_Games.csv")

beauty <- beauty[1:10,]
beauty_sp <- sdf_copy_to(sc, beauty, "beauty_df", overwrite = TRUE)

# Copy data to Spark
tic()
games_sp <- sdf_copy_to(sc, games[1:100,], "games_df", overwrite = TRUE)
t <- toc(quiet = TRUE)
timing <- rbind(timing, data.frame(Process = "Copy Data Frame to Spark", Time = round(t$toc - t$tic, 2)))

head(games_sp)

# Convert IDs to numeric for use in ALS
games_sp <- games_sp %>%
  ft_string_indexer(input_col = "UserID", output_col = "UserIDn") %>%
  ft_string_indexer(input_col = "ProductID", output_col = "ProductIDn")

# Split for trainig and testing
games_partition <- sdf_partition(games_sp, training = 0.8, testing = 0.2)
sdf_register(games_partition, c("games_train","games_test"))

games_tidy_train <- tbl(sc,"games_train") %>%
  select(UserIDn, ProductIDn, Rating)

# Build model
tic()
sparkALS <- ml_als(games_tidy_train, max_iter = 5, nonnegative = TRUE, 
                   rating_col = "Rating", user_col = "UserIDn", item_col = "ProductIDn")
t <- toc(quiet = TRUE)
timing <- rbind(timing, data.frame(Process = "Building ALS Model", Time = round(t$toc - t$tic, 2)))

# Run prediction
games_test <- tbl(sc, "games_test")

pred_iris <- sdf_predict(
  model_iris, test_iris) %>%
  collect 


tic()
sparkPred <- sparkALS$.jobj %>%
  invoke("transform", spark_dataframe(spark_test)) %>%
  collect()
t <- toc(quiet = TRUE)


sparkPred <- sparkPred[!is.na(sparkPred$prediction), ] # Remove NaN due to data set splitting

# Calculate error
mseSpark <- mean((sparkPred$Rating - sparkPred$prediction)^2)
rmseSpark <- sqrt(mseSpark)
maeSpark <- mean(abs(sparkPred$Rating - sparkPred$prediction))


# Disconnect from Spark
spark_disconnect(sc)
