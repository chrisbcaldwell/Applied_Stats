# Bootstrapping exercise in R and Go

## Introduction

This project compares techniques and execution time in bootstrapping a standard error of the median for three selected baseball statistics.

Bootstrapping estimates a statistical parameter from a sample by taking samples of equal size from the original sample, with replacement.  For example, a sample of 1,000 observations will be randomly resampled with 1,000 observations drawn from the original sample.  Because  the sampling is done with replacement, many observations will be represented more than one, and others will not be chosen at all.

From these re-samples, the statistic of interest is calculated.  This is repeated a large number of times, allowing estimation of the variation of the statistic of interest.

## Running the code

Feel free to clone this project and run the scripts on your own machine!

To run the R version, run the file `bootstrap.R` in your preferred method for R scripts.  RStudio was used for the outputs shown here.

To run the first Go version there are two options.  Use the terminal to navigate to your local directory and either:
* use the command `go run bootstrap.go` to run the Go file directly, or
* use the command  `./applied_stats` to run the Go executable file `applied_stats.exe`

For the second Go version that removes reflection, navigate to the subfolder `bootstrap2` in the terminal and follow the instructions above, replacing `bootstrap` with `bootstrap2`.

## Project details

Major League Baseball individual players' single-season batting data was downloaded from the [Fangraphs leaderboard page](https://www.fangraphs.com/leaders/major-league?pos=all&stats=bat&lg=all).  All seasons from 1978 to 2024 were used, filtered by players who had at least ten plate appearances in a season.  Batting average, walk percentage, and runs scored were the selected statistics, with 31,262 player seasons returned in all.

R and Go were used to estimate bootstrapped standard errors for the medians of each statistic.

## Bootstrapping with R

R's `boot` package was used; among choices considered it offered ease of use alongside good performance.  If needed, the packages `boot` and `rlist` can be installed by unhiding the second and/or third lines of code in `bootstrap.R`.

A histogram of the data shows that average (AVG) is left-skewed, runs (R) are right-skewed, and walk percentage (BB.) is not heavily skewed in either direction:

![R histogram of AVG, BB%, R](Rplot01.png)

Bootstrapped standard errors were estimated using `boot` along with the processing time of the operation.  The data was resampled 5,000 times to get the standard error estimates for the median of each statistic:

```
[1] "Statistic: AVG"
[[1]]

ORDINARY NONPARAMETRIC BOOTSTRAP


Call:
boot(data = baseball[, cols[i]], statistic = med, R = N)


Bootstrap Statistics :
     original       bias     std. error
t1* 0.2426036 7.173114e-06 0.0003826049

[1] "Statistic: BB."
[[1]]

ORDINARY NONPARAMETRIC BOOTSTRAP


Call:
boot(data = baseball[, cols[i]], statistic = med, R = N)


Bootstrap Statistics :
      original       bias     std. error
t1* 0.07265697 6.951163e-06 0.0003210851

[1] "Statistic: R"
[[1]]

ORDINARY NONPARAMETRIC BOOTSTRAP


Call:
boot(data = baseball[, cols[i]], statistic = med, R = N)


Bootstrap Statistics :
    original  bias    std. error
t1*       19    0.28   0.4482635

[1] "Total Run Time:"
Time difference of 29.74731 secs
```

The medians of each bootstrapped sample are shown below.  The red line indicates the original sample medians for each statistic of interest:

![R histogram of bootstrapped medians of AVG, BB%, R](Rplot02.png)

For AVG and BB.PCT there could be some skew in each set of bootstrapped medians, though the biases for each are essentially nothing compared to the sample median.  Runs was a binary, unsurprisingly for a discrete variable, with most ending up at 19 and a substantial minority at 20.

## Bootstrapping with Go

The Go program requires the packages `github.com/go-gota/gota/dataframe` and `github.com/Preetam/bootstrap`; to install run the commands `go get github.com/go-gota/gota/dataframe` and `go get github.com/Preetam/bootstrap` from the terminal if running the program from the source code is desired.  _Note: this step is not needed if the program is run from the executable file._

Because bootstrapping isn't as well supported by Go packages as in R, there were some substantial workarounds required to get a standard error of a bootstrapped sampling distribution of a median.  Primarily, the `github.com/Preetam/bootstrap` package does not support standard errors; it was built as a simple Go package that allows confidence intervals to be derived from bootstrapped quantiles representing the lower and upper intervals of the limit.  Building the standard error from scratch is impossible by normal means because the package does not export the iterated bootstrapped medians:

```
// BasicResampler is a basic bootstrap resampler.
type BasicResampler struct {
	aggregator       Aggregator
	iterations       int
	sampleAggregates []float64
	r                rand.Source
}
```

Because none of the field names in the `BasicResampler` type are capitalized, they are not available to the user of the package.  The field `sampleAggregates` contains the statistic of interest for each bootstrapped sample iteration.

A workaround was started based on the blog post by Elsaid detailing using the `reflect` package in the Go standard library to access unexported elements inside an imported element.  There was a crucial problem though: `reflect` as an intentional design philosophy does not allow the user to call functions directly on to the reflected values (with some exceptions like `fmt.Println()` and `refelct.Value.Seq2`), even if the call does not alter the values (Randall 2019).  So, even though access was gained to the values contained in `reflect.BasicResampler.sampleAggregates`, no operations could be performed directly on the data.  Following the advice laid out by Johnson (2024), I tried iterating the underlying values of `sampleAggregates` using `refelct.Value.Seq2`:

```
func getStdErr(br *bootstrap.BasicResampler) float64 {
	stdevValue := reflect.ValueOf(stat.StdDev) // turn the st dev function into a reflect.Value type
	v := reflect.ValueOf(br)
	m := v.Elem().FieldByName("sampleAggregates")
	n := m.Len()
	m2 := make([]float64, n)
	for i, val := range m.Seq2() {
		m2[i.Int()] = val.Float()
	}
	medians := reflect.ValueOf(m2) // have to trick reflect.Value.Call into taking an unexported field
	w := make([]float64, n)
	for i := 0; i < n; i++ {
		w[i] = 1.0
	}
	weights := reflect.ValueOf(w) // stat.StdDev takes a weights argument
	args := []reflect.Value{medians, weights}
	results := stdevValue.Call(args)
	return results[0].Float()
}
```

This approach worked in the sense that it produced resonable results, but as one might expect this Rube Goldberg function had considerable computational expense and the Go program took longer than the R script by about 27%:

```
Variable: AVG
Median 0.24260355
Standard Error: 0.0003799596937815174

Variable: BB%
Median 0.0726569655
Standard Error: 0.00032019736145058223

Variable: R
Median 19
Standard Error: 0.4471073036623247

Bootstrapping run time: 37.7749777s
Total run time: 37.8568044s
```

The main culprit in the reduced performace was likely all the `reflect` calls (Buckley 2024); the most easily implememnted improvement was to simply clone the `bootstrap` package and add my own standard error method.  This did not improve the speed at all.

The **real** main culprit was the `bootstrap` package's sorting of aggregators in the bootstrapping samples.  This was done to facilitate confidence intervals and producing quantiles on demand.  With a standard error, though, that step is unneeded. THe sorting was moved from the Resample method to the Quantile methods, reducing the load for standard error bootstrapping:

```
Variable: AVG
Median 0.24260355
Standard Error: 0.0003799596937815174

Variable: BB%
Median 0.0726569655
Standard Error: 0.00032019736145058223

Variable: R
Median 19
Standard Error: 0.4471073036623247

Bootstrapping run time: 20.3805921s
Total run time: 20.4333388s
```

Total processing time went from 37.9 seconds to 20.4 seconds.

Further improvement would likely be possible by running the three bootstrapping iterations concurrently.

## References

Buckley, Ersin.  "Reflection is slow in Golang," _Ersin's Blog._  May 25, 2024.  https://www.ersin.nz/articles/reflection-is-slow.

Canty, Angelo, and B. D. Ripley.  boot: Bootstrap R (S-Plus) Functions. R package version 1.3-31.  2024.  https://cran.r-project.org/web/packages/boot/index.html.

Elsaid, Emad.  "Access unexported struct fields in Go," _Emad Elsaid_ (Blog).  April 15, 2023.  https://www.emadelsaid.com/Access%20unexported%20struct%20fields%20in%20Go/.

Fangraphs.  _Major Leage Leaderboards - 1978 to 2024 - Batting_.  Accessed May 22, 2025.  https://www.fangraphs.com/leaders/major-league?pos=all&stats=bat&lg=all&type=c%2C23%2C34%2C12&month=0&ind=1&team=0&rost=0&players=0&startdate=&enddate=&season1=1978&season=2024&sortcol=5&sortdir=default&qual=10&v_cr=202301&pagenum=1.

Gerrand, Andrew.  "Error handling and Go," _The Go Blog._  July 12, 2011.  https://go.dev/blog/error-handling-and-go.

Gonum.  stat package.  Go package version 0.16.0.  March 21, 2025.  https://pkg.go.dev/gonum.org/v1/gonum/stat.

Jinka, Preetam.  "Bootstrap for alerting," _Misframe_ (Blog).  May 7, 2017.  https://misfra.me/2017/05/07/bootstrap-for-alerting/.

Jinka, Preetam.  bootstrap package.  Go package version 0.0.0.  November 12, 2017.  https://pkg.go.dev/github.com/preetam/bootstrap.

Johnson, Carlana.  "What’s New in Go 1.23: Iterators and reflect.Value.Seq," _The Ethically-Trained Programmer_ (Blog).  July 29, 2024.  https://blog.carlana.net/post/2024/golang-reflect-value-seq/.

Randall, Keith (GitHub user randall77).  "As a general rule we don't want to allow reflect to do anything that is not allowed in the language (and vice versa).
There are exceptions to this rule, but I don't think we want to go any further in that direction."  Comment on GitHub issue.  June 4, 2019.  https://github.com/golang/go/issues/32438.

Sánchez Brotons, Alejandro.  dataframe package.  Go package version 0.12.0.  October 10, 2021.  https://pkg.go.dev/github.com/go-gota/gota@v0.12.0/dataframe.

