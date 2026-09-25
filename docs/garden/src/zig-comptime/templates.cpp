#include <cstddef>
#include <cstdio>

// --8<-- [start:code]
// constexpr-функция: вызывается и при компиляции, и при выполнении.
constexpr unsigned fib(unsigned n) {
    return n < 2 ? n : fib(n - 1) + fib(n - 2);
}
static_assert(fib(10) == 55, "проверено компилятором");

// Шаблон функции и шаблон структуры — отдельный подъязык с <...>.
template <typename T>
T max_of(T a, T b) {
    return a > b ? a : b;
}

template <typename T, std::size_t N>
struct Stack {
    T items[N];
    std::size_t len = 0;
    void push(T v) { items[len++] = v; }
    T pop() { return items[--len]; }
};

int main() {
    int buf[fib(6)];  // размер массива — константное выражение
    unsigned n = 7;   // значение времени выполнения
    std::printf("%zu %u\n", sizeof buf / sizeof buf[0], fib(n));
    std::printf("%d %.1f\n", max_of(3, 5), max_of(2.5, 1.5));

    Stack<int, 4> s;
    s.push(10);
    s.push(20);
    std::printf("%d\n", s.pop());
}
// --8<-- [end:code]
