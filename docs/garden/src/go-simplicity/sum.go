package main

import (
	"fmt"
	"strconv"
)

// sum складывает числа, записанные строками.
// Ошибка — обычное значение: второй результат функции.
func sum(lines []string) (int, error) {
	total := 0
	for i, line := range lines {
		n, err := strconv.Atoi(line)
		if err != nil {
			return 0, fmt.Errorf("строка %d: %w", i+1, err)
		}
		total += n
	}
	return total, nil
}

func main() {
	inputs := [][]string{
		{"10", "20", "30"},
		{"10", "x", "30"},
	}
	for _, in := range inputs {
		total, err := sum(in)
		if err != nil {
			fmt.Println("ошибка:", err)
			continue
		}
		fmt.Println("сумма:", total)
	}
}
