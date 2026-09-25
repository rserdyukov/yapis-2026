const std = @import("std");

fn describe(comptime T: type) []const u8 {
    return switch (@typeInfo(T)) {
        .int => "целое",
        .float => "с плавающей точкой",
        .bool => "логическое",
        else => @compileError("нет описания для " ++ @typeName(T)),
    };
}

// --8<-- [start:code]
const Point = struct { x: i32, y: i32 };

// Никто не вызывает эту функцию — её тело не проходит семантический анализ,
// поэтому ошибка типов в ней не будет обнаружена.
fn neverCalled() void {
    const x: u8 = "не число";
    _ = x;
}

pub fn main() void {
    std.debug.print("{s}\n", .{describe(Point)}); // ошибка компиляции
}
// --8<-- [end:code]
