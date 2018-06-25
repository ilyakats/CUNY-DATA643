# SVD Example
hilbert <- function(n) { i <- 1:n; 1 / outer(i - 1, i, "+") }
X <- hilbert(9)[, 1:6]
(s <- svd(X))
D <- diag(s$d)
s$u %*% D %*% t(s$v) #  X = U D V'
t(s$u) %*% X %*% s$v #  D = U' X V

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
