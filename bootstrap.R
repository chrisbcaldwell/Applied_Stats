# uncomment to install packages if needed
# install.packages("boot")
# install.packages("rlist")

library(boot)
library(ggplot2)
library(tidyr)
library(dplyr)
library(rlist)

# start the benchmarking clock for overall operation
t0 <- Sys.time()

# working directory to same directory as script
setwd(dirname(parent.frame(2)$ofile))

# read the data into the data frame baseball
baseball <- read.csv("baseball.csv")

# give the walk% column, currently 'BB.', a better name
names(baseball)[names(baseball) == 'BB.'] <- 'BB.PCT'

# bootstrapping specifics
cols <- c('AVG', 'BB.PCT', 'R')
N <- 5000 # number of bootstrapping replicates

# median function that can take the bootstrapping indices
med <- function(data, indices) {
  d <- data[indices] # lets boot select samples
  return(median(d))
}

# start the clock for benchmarking
t_boot0 <- Sys.time()

boots <- list()
for (i in 1:length(cols)) {
  boots <- list.append(boots, boot(baseball[,cols[i]], med, N))
}

for (i in 1:length(cols)) {
  print(paste("Statistic:",cols[i]))
  print(boots[i])
}

# stop the clock and get times
end <- Sys.time()
elapsed <- end - t0
elapsed_boot <- end - t_boot0

print("Total Run Time:")
print(elapsed)
print("Bootstrapping Run Time:")
print(elapsed_boot)

# plot the distributions, removing the row identifiers
p1 <- ggplot(gather(subset(baseball, select=-c(Season, Name, Team, NameASCII, PlayerId, MLBAMID))), aes(value)) + 
  geom_histogram(bins = 40) + 
  facet_wrap(~key, scales = 'free_x') +
  ggtitle("Distributions of AVG, BB.PCT, and R")
print(p1)


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
  facet_wrap(~key, scales = 'free_x') +
  ggtitle("Distributions of bootstrapped medians of AVG, BB.PCT, and R",
          subtitle = "Sample median in red") +
  theme(legend.position = "none")
print(p2)
