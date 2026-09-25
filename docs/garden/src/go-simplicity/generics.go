package main

import "fmt"

// --8<-- [start:sum]
// Number — ограничение: набор типов, для которых определён +.
type Number interface {
	~int | ~int64 | ~float64
}

func Sum[T Number](xs []T) T {
	var total T
	for _, x := range xs {
		total += x
	}
	return total
}

type Celsius float64

func main() {
	fmt.Println(Sum([]int{1, 2, 3}))
	fmt.Println(Sum([]float64{0.5, 0.25}))
	fmt.Println(Sum([]Celsius{36.6, 0.4})) // ~float64 допускает Celsius
}

// --8<-- [end:sum]
