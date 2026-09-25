// Ожидается ошибка компиляции E0106: компилятор не может вывести,
// с каким из аргументов связан результат.
fn longest(a: &str, b: &str) -> &str {
    if a.len() >= b.len() { a } else { b }
}

fn main() {
    println!("{}", longest("abc", "de"));
}
