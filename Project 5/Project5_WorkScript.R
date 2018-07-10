# Install package
install.packages('sparklyr')

# Load package and install local instance
library("sparklyr")
spark_install(version = '2.1.0')

library(sparklyr)
library(dplyr)
sc <- spark_connect(master = "local")





library(recommenderlab)

library(tidyr)

# Import original file and select sample for project
ratings <- read.csv("c:/temp/CUNY/data643/ratings_Beauty.csv")
ratings <- read.csv("F:/CUNY/GitHub/ratings_Beauty.csv")

# Explore
head(ratings)
class(ratings$UserId); class(ratings$ProductId); class(ratings$Rating); class(ratings$Timestamp)
hist(ratings$Rating)

# Convert to realRatingMatrix
ratingsMatrix <- sparseMatrix(as.integer(ratings$UserId), as.integer(ratings$ProductId), x = ratings$Rating)
colnames(ratingsMatrix) <- levels(ratings$ProductId)
rownames(ratingsMatrix) <- levels(ratings$UserId)
amazon <- as(ratingsMatrix, "realRatingMatrix")

# Explore
amazon 
hist(rowCounts(amazon))
table(rowCounts(amazon))
hist(colCounts(amazon))
table(colCounts(amazon))

# Select Subset 1
( amazonShort <- amazon[rowCounts(amazon) > 10, colCounts(amazon) > 30] )

# Select Subset 2
amazonShort <- amazon[ , colCounts(amazon) > 30]
amazonShort <- amazonShort[rowCounts(amazonShort) > 10, ]
amazonShort

# Check
table(rowCounts(amazonShort))
table(colCounts(amazonShort))

# Remove empty items
( amazonShort <- amazonShort[ , colCounts(amazonShort) != 0] )

# Convert to data frame and save as CSV file
df <- as.data.frame(as.matrix(amazonShort@data))
df$UserId <- rownames(df)
df <- df %>% gather(key = ProductId, value = Rating, -UserId) %>% filter(Rating != 0)
write.csv(df, "c:/temp/CUNY/data643/ratings_Short.csv", row.names = FALSE)
write.csv(df, "F:/CUNY/GitHub/ratings_Short.csv", row.names = FALSE)

