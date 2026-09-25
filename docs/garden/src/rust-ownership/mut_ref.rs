// Функция получает исключительную ссылку и меняет данные вызывающего.
fn push_twice(v: &mut Vec<i32>, x: i32) {
    v.push(x);
    v.push(x);
}

fn sum(v: &[i32]) -> i32 {
    v.iter().sum()
}

fn main() {
    let mut v = vec![1];
    push_twice(&mut v, 7); // заимствование &mut заканчивается после вызова
    let a = &v; // теперь можно брать сколько угодно разделяемых ссылок
    let b = &v;
    println!("{:?} sum={} len={}", v, sum(a), b.len());
}
