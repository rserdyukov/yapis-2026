const std = @import("std");

// --8<-- [start:code]
// Обычная функция: ни одного слова о времени компиляции.
fn fibonacci(n: u32) u32 {
    if (n < 2) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

// На уровне контейнера (вне функций) выражения вычисляются при компиляции.
const fib7 = fibonacci(7);

fn squares(comptime n: usize) [n]u32 {
    var result: [n]u32 = undefined;
    for (&result, 0..) |*slot, i| {
        slot.* = @intCast(i * i);
    }
    return result;
}
const table = squares(5); // готовая таблица попадёт в двоичный файл

pub fn main() void {
    // Длина массива — часть типа, значит вызов выполняется при компиляции.
    var array: [fibonacci(6)]i32 = undefined;
    @memset(&array, 42);

    // Явный comptime-блок: проверка, которую выполняет компилятор.
    comptime {
        std.debug.assert(fib7 == 13);
    }

    std.debug.print("fib7 = {d}, array.len = {d}, table[4] = {d}\n", .{ fib7, array.len, table[4] });

    // Та же функция во время выполнения: i здесь не известен компилятору.
    for (0..6) |i| {
        std.debug.print("{d} ", .{fibonacci(@intCast(i))});
    }
    std.debug.print("\n", .{});
}
// --8<-- [end:code]
