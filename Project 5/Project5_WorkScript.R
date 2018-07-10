# Install package
install.packages('sparklyr')

# Load package and install local instance
library(sparklyr)
spark_install(version = '2.1.0')

library(sparklyr)
library(dplyr)
sc <- spark_connect(master = "local")


head(ratings)
