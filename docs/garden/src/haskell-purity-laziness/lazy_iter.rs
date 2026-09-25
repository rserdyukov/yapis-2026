// Rust: язык строгий, но адаптеры итераторов ленивы — работа идёт,
// только когда потребитель (collect, sum, for) запрашивает элементы.
fn main() {
    let it = (1..).map(|x| {
        println!("  map {x}");
        x * x
    });
    println!("итератор построен, ничего не вычислено");
    let v: Vec<u64> = it.filter(|x| x % 2 == 1).take(3).collect();
    println!("{v:?}");

    let fibs = std::iter::successors(Some((0u64, 1u64)), |&(a, b)| Some((b, a + b)))
        .map(|(a, _)| a);
    println!("{:?}", fibs.take(10).collect::<Vec<_>>());

    // Без потребителя компилятор предупреждает: адаптеры ничего не делают сами.
    (0..3).map(|x| println!("никогда не напечатается {x}"));
}
