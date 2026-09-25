// --8<-- [start:code]
// macro_rules! работает с деревьями токенов, а фрагмент $x:expr —
// уже разобранное выражение: скобки вокруг него не нужны.
macro_rules! square {
    ($x:expr) => {
        $x * $x
    };
}

// Аргумент вычисляется один раз, потому что макрос связывает его с let.
macro_rules! max {
    ($a:expr, $b:expr) => {{
        let a = $a;
        let b = $b;
        if a > b { a } else { b }
    }};
}

// Гигиена: i внутри макроса и i в месте вызова — разные переменные.
macro_rules! print_twice {
    ($e:expr) => {
        for i in 0..2 {
            let _ = i;
            println!("  {}", $e);
        }
    };
}

// const fn — отдельный, более узкий режим того же языка.
const fn fib(n: u32) -> u32 {
    if n < 2 { n } else { fib(n - 1) + fib(n - 2) }
}
const FIB10: u32 = fib(10);

fn main() {
    println!("square!(1 + 2) = {}", square!(1 + 2));

    let mut i = 3;
    let m = max!({ i += 1; i - 1 }, 2); // «i++» в стиле Rust
    println!("max!(i++, 2) = {m}, i = {i}");

    let i = 7;
    println!("print_twice!(i * 10):");
    print_twice!(i * 10);

    let buf = [0u8; fib(6) as usize];
    println!("FIB10 = {FIB10}, buf.len() = {}", buf.len());
}
// --8<-- [end:code]
