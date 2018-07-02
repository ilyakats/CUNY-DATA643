library(recommenderlab)
library(dplyr)
library(tidyr)

# Import original file and select sample for project
ratings <- read.csv("c:/temp/CUNY/data643/ratings_Beauty.csv")
head(ratings)
class(ratings$UserId); class(ratings$ProductId); class(ratings$Rating); class(ratings$Timestamp)
hist(ratings$Rating)

ratingsMatrix <- sparseMatrix(as.integer(ratings$UserId), as.integer(ratings$ProductId), x = ratings$Rating)
colnames(ratingsMatrix) <- levels(ratings$ProductId)
rownames(ratingsMatrix) <- levels(ratings$UserId)
ratingsMatrix[1:50, 1:50]
dim(ratingsMatrix)

amazon <- as(ratingsMatrix, "realRatingMatrix")
amazon 
hist(rowCounts(amazon))
table(rowCounts(amazon))
hist(colCounts(amazon))
table(colCounts(amazon))

( amazonShort <- amazon[rowCounts(amazon) > 10, colCounts(amazon) > 30] )
table(rowCounts(amazonShort))
table(colCounts(amazonShort))
( amazonShort <- amazonShort[ , colCounts(amazonShort) != 0] )
amazonShort@data[1:100, 1:10]
hist(rowCounts(amazonShort))

df <- as.data.frame(as.matrix(amazonShort@data))
df$UserId <- rownames(df)
df <- df %>% gather(key = ProductId, value = Rating, -UserId) %>% filter(Rating != 0)
# df[df == 0] <- NA
# df[1:10, 1:10]
write.csv(df, "c:/temp/CUNY/data643/ratings_Short.csv", row.names = FALSE)
