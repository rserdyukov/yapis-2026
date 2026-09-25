// RAII: деструктор Drop вызывается автоматически при выходе владельца из области.
struct Noisy(&'static str);

impl Drop for Noisy {
    fn drop(&mut self) {
        println!("drop {}", self.0);
    }
}

fn take(n: Noisy) {
    println!("take получила {}", n.0);
} // n уничтожается здесь, а не в main

fn main() {
    let _a = Noisy("a");
    let b = Noisy("b");
    {
        let _c = Noisy("c");
        println!("конец внутреннего блока");
    }
    take(b);
    let _d = Noisy("d");
    println!("конец main");
} // локальные переменные уничтожаются в обратном порядке объявления: d, затем a
