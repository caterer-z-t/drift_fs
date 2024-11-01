# Install packages if not already installed
if (!requireNamespace("caret", quietly = TRUE)) install.packages("caret")
if (!requireNamespace("randomForest", quietly = TRUE)) install.packages("randomForest")
if (!requireNamespace("shapviz", quietly = TRUE)) install.packages("shapviz")
 
# Load libraries
library(caret)
library(randomForest)
library(shapviz)
