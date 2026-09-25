use std::num::ParseIntError;

// Ошибка — часть типа результата; `?` и `collect` прячут шаблонный код.
fn total(lines: &[&str]) -> Result<i64, ParseIntError> {
    let nums = lines
        .iter()
        .map(|s| s.parse::<i64>())
        .collect::<Result<Vec<_>, _>>()?;
    Ok(nums.iter().sum())
}

fn main() {
    for lines in [["10", "20", "30"], ["10", "x", "30"]] {
        match total(&lines) {
            Ok(t) => println!("сумма: {t}"),
            Err(e) => println!("ошибка: {e}"),
        }
    }
}
