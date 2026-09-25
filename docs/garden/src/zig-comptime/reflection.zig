const std = @import("std");

// --8<-- [start:code]
const Header = struct {
    magic: u32,
    name: []const u8,
};

// inline for разворачивается при компиляции: на каждой итерации
// field — значение времени компиляции, и его тип может быть разным.
fn printFields(comptime T: type) void {
    inline for (@typeInfo(T).@"struct".fields) |field| {
        std.debug.print("{s}: {s}\n", .{ field.name, @typeName(field.type) });
    }
}

// Ветвь выбирается по типу; ошибочная ветвь анализируется,
// только если её выбрали.
fn describe(comptime T: type) []const u8 {
    return switch (@typeInfo(T)) {
        .int => "целое",
        .float => "с плавающей точкой",
        .bool => "логическое",
        else => @compileError("нет описания для " ++ @typeName(T)),
    };
}

pub fn main() void {
    printFields(Header);

    std.debug.print("u8: {s}, f64: {s}, bool: {s}\n", .{ describe(u8), describe(f64), describe(bool) });

    // Кортеж разнородных значений обходится только развёрнутым циклом.
    const values = .{ @as(u8, 1), true, @as(f32, 2.5) };
    inline for (values) |v| {
        std.debug.print("{s} ", .{@typeName(@TypeOf(v))});
    }
    std.debug.print("\n", .{});
}
// --8<-- [end:code]
