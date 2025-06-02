package main

import (
	"fmt"
	"log"
	"os"

	"github.com/Preetam/bootstrap"
	"github.com/go-gota/gota/dataframe"
)

func main() {
	df, err := readToDataFrame(filepath)
	if err != nil {
		fmt.Println("Terminating process")
		log.Fatal(err)
	}

	cols := []string{"AVG", "BB.", "R"}
	for _, col := range cols {
		// possible insertion of concurrency here
		s := df.Col(col)
		vals := s.Float()
		fmt.Println(vals) // temp to de-squiggly
	}

	fmt.Println(cols)
	notsomethingiintendtokeep()
	columnAsFloat(df)
	// temp
	fmt.Println(df)

}

const (
	filepath = "./baseball.csv" // can alter this to any path where CSV file is located
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

func columnAsFloat(df dataframe.DataFrame) {
	// df should be one column
	fmt.Println(df) // temp delete this

}

func notsomethingiintendtokeep() {

	tacos := bootstrap.SumAggregator{}.Aggregate([]float64{
		6.49, 4.62, 5.08, 7.73, 6.81, 7.77, 7.52, 5.33, 6.86, 4.29,
		6.57, 5.71, 5.74, 6.39, 4.03, 5.27, 7.66, 6.13, 6.21, 6.96,
		5.23, 5.37, 6.90, 5.72, 4.17, 7.22, 4.32, 5.11, 6.86, 4.19,
		6.11, 5.17, 5.43, 4.00, 6.11, 7.35, 7.21, 4.31, 7.51, 7.33,
		7.55, 4.19, 6.77, 7.50, 5.09, 4.31, 6.66, 6.05, 5.24, 5.95,
	})
	fmt.Println(tacos)
}
