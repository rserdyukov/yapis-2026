const std = @import("std");

// --8<-- [start:max]
// Тип — обычный параметр, только известный при компиляции.
fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}
// --8<-- [end:max]

// --8<-- [start:stack]
// Обобщённая структура данных — функция, которая возвращает тип.
fn Stack(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();

        items: [capacity]T = undefined,
        len: usize = 0,

        pub fn push(self: *Self, value: T) void {
            self.items[self.len] = value;
            self.len += 1;
        }

        pub fn pop(self: *Self) T {
            self.len -= 1;
            return self.items[self.len];
        }
    };
}
// --8<-- [end:stack]

// --8<-- [start:main]
pub fn main() void {
    std.debug.print("{d} {d}\n", .{ max(i32, 3, 5), max(f64, 2.5, 1.5) });

    const IntStack = Stack(i32, 4); // тип можно сохранить в константу
    var s: IntStack = .{};
    s.push(10);
    s.push(20);
    const top = s.pop();
    std.debug.print("pop: {d}, len: {d}\n", .{ top, s.len });
}
// --8<-- [end:main]
