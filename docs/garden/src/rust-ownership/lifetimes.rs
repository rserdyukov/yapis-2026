// Явный параметр времени жизни: результат живёт не дольше обоих аргументов.
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}

fn main() {
    let x = String::from("длинная строка");
    let result;
    {
        let y = String::from("коротко");
        result = longest(&x, &y);
        println!("{result}"); // здесь x и y ещё живы — всё корректно
    }
    // println!("{result}"); // раскомментируйте: E0597, y уже уничтожена
}
