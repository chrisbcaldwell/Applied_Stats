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

# give the walk% column, currently 'BB.', a better name
names(baseball)[names(baseball) == 'BB.'] <- 'BB.PCT'

# plot the distributions, removing the row identifiers
p1 <- ggplot(gather(subset(baseball, select=-c(Season, Name, Team, NameASCII, PlayerId, MLBAMID))), aes(value)) + 
  geom_histogram(bins = 40) + 
  facet_wrap(~key, scales = 'free_x')
print(p1)

# bootstrapped medians of the selected statistics
cols <- c('AVG', 'BB.PCT', 'R')
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

print("Total Run Time:")
print(elapsed)

# plot the bootstrap sampling distributions of the median
boot_medians <- data.frame(
  AVG = boots[[1]]$t,
  BB.PCT = boots[[2]]$t,
  R = boots[[3]]$t
)

medians <- data.frame(
  key = cols,
  median = c(boots[[1]]$t0, boots[[2]]$t0, boots[[3]]$t0)
)

p2 <- ggplot(gather(boot_medians), aes(value)) + 
  geom_histogram(bins = 100) +
  geom_vline(data = medians, aes(xintercept = median, color = 'red')) +
  facet_wrap(~key, scales = 'free_x')
print(p2)
