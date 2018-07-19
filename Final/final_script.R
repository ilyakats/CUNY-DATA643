# Install libraries if needed
install.packages("tictoc")
install.packages("aws.s3")
install.packages("sparklyr")

# Set up data frame to track processing times
library(tictoc)
timing <- data.frame(Process=character(), Time=double())

library(sparklyr)
library(dplyr)

Sys.setenv(SPARK_HOME="/usr/lib/spark")

# Open Spark connection
tic()
step <- "Establish Spark Connection"
config <- spark_config()
#config$spark.executor.memory <- "8G"
#config$spark.executor.cores <- 2
#config$spark.executor.instances <- 3
#config$spark.dynamicAllocation.enabled <- "false"
sc <- spark_connect(master = "yarn-client", config = config, version = '2.1.0')
t <- toc(quiet = TRUE)
timing <- rbind(timing, data.frame(Process = step, Time = round(t$toc - t$tic, 2)))

# Set up S3 and read data to Spark
ctx <- spark_context(sc)
jsc <- invoke_static(sc, "org.apache.spark.api.java.JavaSparkContext", "fromSparkContext", ctx)
hconf <- jsc %>% invoke("hadoopConfiguration")
hconf %>% invoke("set","fs.s3a.access.key", "AKIAIIYT6UBO6W33Z5MA")
hconf %>% invoke("set","fs.s3a.secret.key", "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")

tic()
step <- "Read Data from S3 to Spark"
games <- spark_read_csv(sc, name = "games_df", 
                        path = "s3a://data643summer18/ratings_Video_Games.csv", 
                        overwrite = TRUE, header = FALSE)
t <- toc(quiet = TRUE)
timing <- rbind(timing, data.frame(Process = step, Time = round(t$toc - t$tic, 2)))

# Data exploration
head(games)

games <- games %>% 
  rename(UserID = V1) %>%
  rename(ProductID = V2) %>%
  rename(Rating = V3) %>%
  rename(Timestamp = V4)

# Convert IDs to numeric for use in ALS
tic()
step <- "Data Conversion: String to Integer"
games <- games %>%
  ft_string_indexer(input_col = "UserID", output_col = "UserIDn") %>%
  ft_string_indexer(input_col = "ProductID", output_col = "ProductIDn")
t <- toc(quiet = TRUE)
timing <- rbind(timing, data.frame(Process = step, Time = round(t$toc - t$tic, 2)))

# Split for trainig and testing
games_partition <- sdf_partition(games, training = 0.8, testing = 0.2)
sdf_register(games_partition, c("games_train", "games_test"))

games_tidy_train <- tbl(sc, "games_train") %>%
  select(UserIDn, ProductIDn, Rating)

# Build model
tic()
step <- "Building ALS Model"
sparkALS <- ml_als(games_tidy_train, max_iter = 5, nonnegative = TRUE, 
                   rating_col = "Rating", user_col = "UserIDn", item_col = "ProductIDn")
t <- toc(quiet = TRUE)
timing <- rbind(timing, data.frame(Process = step, Time = round(t$toc - t$tic, 2)))

# Run prediction
games_test <- tbl(sc, "games_test")

tic()
step <- "Predict Ratings Using ALS Model"
games_pred <- ml_predict(sparkALS, games_test)
t <- toc(quiet = TRUE)
timing <- rbind(timing, data.frame(Process = step, Time = round(t$toc - t$tic, 2)))

tic()
step <- "Read Results into Data Frame"
prediction <- collect(games_pred)
t <- toc(quiet = TRUE)
timing <- rbind(timing, data.frame(Process = step, Time = round(t$toc - t$tic, 2)))

head(prediction)

# Calculate error
sparkPred <- prediction[!is.na(prediction$prediction), ] # Remove NaN due to data set splitting
rmseSpark <- sqrt(mean((sparkPred$Rating - sparkPred$prediction)^2))
rmseSpark

# Clean up
spark_disconnect(sc)

# RMSE: 1.8986

# PROCESS                              TIME
# Establish Spark Connection          22.48
# Read Data from S3 to Spark           7.08
# Data Conversion: String to Integer  10.19
# Building ALS Model                 164.30
# Predict Ratings Using ALS Model      0.17
# Read Results into Data Frame       630.93