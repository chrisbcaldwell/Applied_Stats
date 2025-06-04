package main

import (
	"fmt"
	"log"
	"os"
	"reflect"
	"time"

	"github.com/Preetam/bootstrap"
	"github.com/go-gota/gota/dataframe"
	"gonum.org/v1/gonum/stat"
)

func main() {
	start := time.Now()
	df, err := readToDataFrame(filepath)
	if err != nil {
		fmt.Println("Terminating process")
		log.Fatal(err)
	}

	cols := []string{"AVG", "BB%", "R"}
	iterations := 5000
	bootstart := time.Now()                        // start the bootstrapping clock
	median := bootstrap.NewQuantileAggregator(0.5) // define the median for bootstrap
	resampler := bootstrap.NewBasicResampler(median, iterations)
	for _, col := range cols {
		// possible insertion of concurrency here
		// would need to create new resmapler here instead of before loop
		s := df.Col(col)
		vals := s.Float()
		resampler.Resample(vals)
		sd := getStdErr(resampler)
		fmt.Println("Variable:", col)
		fmt.Println("Median", s.Median())
		fmt.Println("Standard Error:", sd)
		fmt.Println()
		resampler.Reset()
	}

	fmt.Println("Bootstrapping run time:", time.Since(bootstart))
	fmt.Println("Total run time:", time.Since(start))
}

const (
	filepath = "baseball.csv" // can alter this to any path where CSV file is located
)

func readToDataFrame(p string) (dataframe.DataFrame, error) {
	f, err := os.Open(p)
	if err != nil {
		fmt.Println("Unable to read input file " + filepath)
		return dataframe.New(), err
	}
	defer f.Close()

	df := dataframe.ReadCSV(f)
	return df, nil
}

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
