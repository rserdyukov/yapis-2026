package main

import "fmt"

// --8<-- [start:defer]
func withDefer() {
	defer fmt.Println("defer 1")
	defer fmt.Println("defer 2")
	fmt.Println("тело функции")
}

// --8<-- [end:defer]

// --8<-- [start:chan]
// square читает числа из in и отправляет квадраты в out.
func square(in <-chan int, out chan<- int) {
	defer close(out)
	for v := range in {
		out <- v * v
	}
}

func main() {
	withDefer()

	in := make(chan int)
	out := make(chan int)
	go square(in, out) // отдельная горутина

	go func() {
		defer close(in)
		for i := 1; i <= 5; i++ {
			in <- i
		}
	}()

	total := 0
	for v := range out { // цикл закончится, когда out закроют
		total += v
	}
	fmt.Println("сумма квадратов:", total)
}

// --8<-- [end:chan]
