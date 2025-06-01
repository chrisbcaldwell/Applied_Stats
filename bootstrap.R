# uncomment to install packages if needed
# install.packages("boot")
# install.packages("rlist")

library(boot)
library(ggplot2)
library(tidyr)
library(dplyr)
library(rlist)

# working directory to same directory as script
setwd(dirname(parent.frame(2)$ofile))

# read the data into the data frame baseball
baseball <- read.csv("baseball.csv")
head(baseball)

# plot the distributions, removing the row identifiers
ggplot(gather(subset(baseball, select=-c(Season, Name, Team, NameASCII, PlayerId, MLBAMID))), aes(value)) + 
  geom_histogram(bins = 40) + 
  facet_wrap(~key, scales = 'free_x')

# bootstapped medians of the selected statistics
cols <- c('AVG', 'BB.', 'R')
N <- 5000 # number of bootstrapping replicates

# median function that can take the bootstrapping indices
med <- function(data, indices) {
  d <- data[indices] # lets boot select samples
  return(median(d))
}

# start the clock for benchmarking
t0 <- Sys.time()

boots <- list()
for (i in 1:length(cols)) {
  boots <- list.append(boots, boot(baseball[,cols[i]], med, N))
}

for (i in 1:length(cols)) {
  print(paste("Statistic:",cols[i]))
  print(boots[i])
}

elapsed <- Sys.time() - t0

print("\n\n\nTotal Run Time:")
print(elapsed)
