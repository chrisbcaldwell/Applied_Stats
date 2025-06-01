# Bootstrapping exercise in R and Go

## Introduction

This project compares techniques and execution time in bootstrapping a standard error of the median for three selected baseball statistics.

## Running the code

Feel free to clone this project and run the scripts on your own machine!

To run the R version, run the file `bootstrap.R` in your preferred method for R scripts.  RStudio was used for the outputs shown here.

To run the Go version there are two options.  Use the terminal to navigate to your local directory and either:
* use the command `go run bootstrap.go` to run the Go file directly, or
* use the command  `bootstrap` to run the Go executable file `bootstrap.exe`

## Project details

Major League Baseball individual players' single-season batting data was downloaded from the [Fangraphs leaderboard page](https://www.fangraphs.com/leaders/major-league?pos=all&stats=bat&lg=all).  All seasons from 1978 to 2024 were used, filtered by players who had at least ten plate appearances in a season.  Batting average, walk percentage, and runs scored were the selected statistics, with 31,262 player seasons returned in all.

R and Go were used to estimate bootstrapped standard errors for the medians of each statistic.

## Bootstrapping with R

R's `boot` package was used; among choices considered it offered ease of use alongside good performance.

A histogram of the data shows that average (AVG) is left-skewed, runs (R) are right-skewed, and walk percentage (BB.) is not heavily skewed in either direction:



## References

fangraphs leaderboard
https://www.fangraphs.com/leaders/major-league?pos=all&stats=bat&lg=all&type=c%2C23%2C34%2C12&month=0&ind=1&team=0&rost=0&players=0&startdate=&enddate=&season1=1978&season=2024&sortcol=5&sortdir=default&qual=10&v_cr=202301&pagenum=1

boot package
https://cran.r-project.org/web/packages/boot/index.html
Angelo Canty, B. D. Ripley (2024). boot: Bootstrap R (S-Plus) Functions. R package version 1.3-31.



