//! Пример-витрина: Rust (edition 2021).
//!
//! Одна программа, в которой прокомментированы конструкции, соответствующие
//! концепциям каталога. Маркеры `--8<--` размечают секции для сайта и не
//! влияют на компиляцию. Собрать: `rustc showcase.rs`.

use std::io;

// --8<-- [start:req-8-2]
// 8.2. Глобальная область видимости: `static` — переменная времени жизни
// всей программы; изменяемая `static mut` требует `unsafe`, поэтому для
// изменяемого глобального состояния используют атомики или Mutex.
static GREETING: &str = "ЯПИС";
static COUNTER: std::sync::atomic::AtomicU32 = std::sync::atomic::AtomicU32::new(0);
// --8<-- [end:req-8-2]

// --8<-- [start:variants-9]
// 9. Функцию можно объявить в любом месте модуля и внутри другой функции.
// Вложенная `fn` не захватывает переменные внешней — для этого есть замыкания.
fn outer(x: i32) -> i32 {
    fn inner(y: i32) -> i32 {
        y + 1
    }
    let add_x = |y: i32| x + y; // замыкание видит x
    inner(add_x(1))
}
// --8<-- [end:variants-9]

// --8<-- [start:variants-7]
// 7. Перегрузки функций нет: два `fn` с одним именем в одной области — ошибка.
// Поведение для разных типов задаётся трейтами (ad-hoc полиморфизм).
trait Describe {
    fn describe(&self) -> String;
}
impl Describe for i32 {
    fn describe(&self) -> String {
        format!("целое {}", self)
    }
}
impl Describe for f64 {
    fn describe(&self) -> String {
        format!("дробное {}", self)
    }
}
// --8<-- [end:variants-7]

// --8<-- [start:variants-8]
// 8. Передача параметров. Типы с Copy (числа) — по значению; остальные —
// перемещением (move): после вызова исходная переменная недоступна.
// Заимствование `&T` даёт доступ на чтение, `&mut T` — на запись; компилятор
// проверяет, что изменяемая ссылка единственна.
fn takes_by_value(n: i32) -> i32 {
    n + 1
}
fn takes_ownership(v: Vec<i32>) -> usize {
    v.len() // v освобождается здесь
}
fn borrows(v: &Vec<i32>) -> i32 {
    v.iter().sum()
}
fn borrows_mut(v: &mut Vec<i32>) {
    v.push(5); // видно вызывающему
}
// --8<-- [end:variants-8]

// --8<-- [start:req-4]
// 4. Ввод-вывод: `println!` — макрос стандартной библиотеки, ввод — через
// `std::io::stdin()`; встроенных функций read/write в языке нет.
fn read_int() -> Result<i32, String> {
    let mut line = String::new();
    io::stdin()
        .read_line(&mut line)
        .map_err(|e| e.to_string())?;
    line.trim().parse::<i32>().map_err(|e| e.to_string())
}
// --8<-- [end:req-4]

fn main() {
    // --8<-- [start:variants-1]
    // 1. Объявление явное — ключевое слово `let`; тип указывается либо
    // выводится компилятором. Переменные неизменяемы без `mut`.
    let total: i32 = 0;
    let mut count = 42; // тип i32 выведен
    // --8<-- [end:variants-1]

    // --8<-- [start:variants-2]
    // 2. Преобразование типов только явное: `as` для примитивов,
    // `From`/`Into` и `parse` для остальных. Неявного приведения i32 → f64 нет.
    let ratio = count as f64 / 5.0;
    let parsed: i32 = "7".parse().unwrap();
    // let bad = count / 5.0; // ошибка компиляции: i32 / f64
    // --8<-- [end:variants-2]

    // --8<-- [start:variants-3]
    // 3. Присваивание одиночное; множественное — через деструктуризацию
    // кортежа (для существующих переменных — с версии 1.59).
    let (mut a, mut b) = (1, 2);
    (a, b) = (b, a);
    count = a + b + parsed;
    // --8<-- [end:variants-3]

    // --8<-- [start:variants-4]
    // 4. Область видимости ограничивают и функции, и любые блоки `{ }`:
    // переменная, объявленная внутри if, после блока недоступна.
    if count > 0 {
        let inside_block = "видна только здесь";
        println!("{inside_block}");
    }
    // println!("{inside_block}"); // ошибка компиляции
    // --8<-- [end:variants-4]

    // --8<-- [start:variants-5]
    // 5. Маркер блока явный — фигурные скобки, даже для одного оператора.
    for i in 0..3 {
        count += i;
    }
    // --8<-- [end:variants-5]

    // --8<-- [start:variants-6]
    // 6. `if` / `else if` / `else` и многовариантный `match` — сопоставление
    // с образцом, обязано покрывать все случаи (проверяет компилятор).
    // Оба — выражения и возвращают значение.
    let size = if count > 100 {
        "много"
    } else if count > 10 {
        "средне"
    } else {
        "мало"
    };
    let label = match (a, b) {
        (1, _) => "первый элемент — единица",
        (_, 1) => "второй элемент — единица",
        _ => "что-то другое",
    };
    println!("{size}, {label}");
    // --8<-- [end:variants-6]

    // --8<-- [start:req-7-3]
    // 7.3. Цикл for — только по итератору (foreach); счётный цикл — это
    // итерация по диапазону `a..b`.
    for ch in GREETING.chars() {
        print!("{ch} ");
    }
    for i in (0..10).step_by(2) {
        print!("{i} ");
    }
    println!();
    // --8<-- [end:req-7-3]

    // --8<-- [start:req-7-2-until]
    // 7.2. Цикла until нет; эквивалент — `while !cond`.
    let mut n = 0;
    while !(n >= 3) {
        n += 1;
    }
    // --8<-- [end:req-7-2-until]

    // --8<-- [start:req-7-2-do-while]
    // Цикла do-while нет; тело выполняется хотя бы раз через `loop` + `break`.
    loop {
        n -= 1;
        if n <= 0 {
            break;
        }
    }
    // --8<-- [end:req-7-2-do-while]

    let v = vec![1, 2, 3];
    let mut w = v.clone();
    println!("{} {}", takes_by_value(count), borrows(&v));
    borrows_mut(&mut w);
    println!("{:?} {}", w, takes_ownership(v)); // v перемещён, дальше недоступен
    println!("{} {} {}", count.describe(), ratio.describe(), outer(41));

    COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
    println!("{} {}", COUNTER.load(std::sync::atomic::Ordering::Relaxed), total);

    if std::env::args().count() > 1 {
        match read_int() {
            Ok(x) => println!("{x}"),
            Err(e) => eprintln!("ошибка ввода: {e}"),
        }
    }
}
