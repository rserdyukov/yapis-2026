package main

import "fmt"

// --8<-- [start:types]
// Интерфейс — только набор методов.
type Namer interface {
	Name() string
}

type Animal struct {
	name string
}

func (a Animal) Name() string { return a.name }
func (a Animal) Describe() string {
	return a.Name() + " — животное"
}

// Dog встраивает Animal: поля и методы Animal продвигаются в Dog.
type Dog struct {
	Animal
	breed string
}

// Dog объявляет собственный Name. Это не переопределение:
// Animal.Describe по-прежнему вызывает Animal.Name.
func (d Dog) Name() string { return "пёс " + d.name }

// --8<-- [end:types]

// --8<-- [start:use]
func greet(n Namer) {
	fmt.Println("привет,", n.Name())
}

func main() {
	d := Dog{Animal: Animal{name: "Шарик"}, breed: "дворняга"}

	greet(d)        // Dog реализует Namer — без слова implements
	greet(d.Animal) // Animal тоже реализует Namer
	fmt.Println(d.Describe())

	// var a Animal = d // ошибка компиляции: Dog не является Animal
}

// --8<-- [end:use]
