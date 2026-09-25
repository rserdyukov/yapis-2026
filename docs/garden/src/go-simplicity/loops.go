package main

import "fmt"

func main() {
	// --8<-- [start:forms]
	// 1. Классический цикл с заголовком из трёх частей.
	sq := 0
	for i := 1; i <= 4; i++ {
		sq += i * i
	}
	fmt.Println("сумма квадратов:", sq)

	// 2. Только условие — это while.
	n, steps := 27, 0
	for n != 1 {
		if n%2 == 0 {
			n /= 2
		} else {
			n = 3*n + 1
		}
		steps++
	}
	fmt.Println("шагов Коллатца для 27:", steps)

	// 3. Без условия — бесконечный цикл; так имитируют do-while.
	x := 100
	for {
		x /= 3
		if x < 5 {
			break
		}
	}
	fmt.Println("x:", x)

	// 4. range — обход коллекции.
	for i, w := range []string{"for", "один"} {
		fmt.Println(i, w)
	}
	// --8<-- [end:forms]
}
