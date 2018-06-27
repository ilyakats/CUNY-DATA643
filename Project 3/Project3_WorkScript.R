# SVD Example
hilbert <- function(n) { i <- 1:n; 1 / outer(i - 1, i, "+") }
X <- hilbert(9)[, 1:6]
(s <- svd(X))
D <- diag(s$d)
s$u %*% D %*% t(s$v) #  X = U D V'
t(s$u) %*% X %*% s$v #  D = U' X V


a <- modelSVD@model$svd$u %*% diag(modelSVD@model$svd$d) %*% t(modelSVD@model$svd$v)
a[1:10, 1:10]

movieMatrix[1:10, 1:10]

movieSVD$u[1:10, 1:10]
movieSVD$v[1:10, 1:10]
movieSVD$d[1:10]
diag(movieSVD$d)[1:10, 1:10]

dim(movieSVD$u)
dim(movieSVD$v)
length(movieSVD$d)

movieTest <- movieSVD$u %*% diag(movieSVD$d) %*% t(movieSVD$v)
round(movieTest[1:10, 1:10],2)
rm(movieTest)



movieMatrix[1:10, 1:10]
movieRealMatrix@data[1:10, 1:10]

movies <- movieRealMatrix
movies@data[1:10, 1:10]

set.seed(88)
which_train <- sample(x = c(TRUE, FALSE), size = nrow(movies),
                      replace = TRUE, prob = c(0.8, 0.2))

movieTrain <- movies[which_train, ]
movieTest <- movies[!which_train, ]
movieTest@data[1:10, 1:10]

movieTrain
movieTest

library(tictoc)

pred <- predict(model, newdata = movieTest, type = "ratings")
calcPredictionAccuracy(svd_preds, ev_unknown)

eval <- evaluationScheme(movies, method = "split", train = 0.8, given = 20, goodRating = 3)
train <- getData(eval, "train")
known <- getData(eval, "known")
unknown <- getData(eval, "unknown")

tic("UBCF Model - Training")
model <- Recommender(train, method = "UBCF") 
toc(log = TRUE, quiet = TRUE)
tic("UBCF Model - Predicting")
pred <- predict(model, newdata = known, type = "ratings")
toc(log = TRUE, quiet = TRUE)
calcPredictionAccuracy(pred, unknown)

tic("SVD Model - Training")
model <- Recommender(train, method = "SVD") 
toc(log = TRUE, quiet = TRUE)
tic("SVD Model - Predicting")
pred <- predict(model, newdata = known, type = "ratings")
toc(log = TRUE, quiet = TRUE)
calcPredictionAccuracy(pred, unknown)

tic.log(format = TRUE)
tic.clearlog()

model <- Recommender(train, method = "SVD", parameter = list(k = 50)) 
pred <- predict(model, newdata = known, type = "ratings")
calcPredictionAccuracy(pred, unknown)

model <- Recommender(train, method = "POPULAR") 
pred <- predict(model, newdata = known, type = "ratings")
calcPredictionAccuracy(pred, unknown)


length(model@model$svd$d)
dim(model@model$svd$v)
pred@data[1:10, 1:10]
known@data[1:10, 1:10]
unknown@data[1:10, 1:10]
