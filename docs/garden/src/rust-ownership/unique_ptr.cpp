// C++: unique_ptr выражает единственного владельца, move передаёт владение,
// но использование после перемещения компилятор не запрещает.
#include <iostream>
#include <memory>
#include <string>
#include <utility>

std::size_t consume(std::unique_ptr<std::string> p) {
    return p->size();
} // деструктор unique_ptr освобождает строку

int main() {
    auto p = std::make_unique<std::string>("hello");
    std::size_t n = consume(std::move(p));
    std::cout << n << "\n";
    std::cout << (p == nullptr ? "p пуст после move" : "p не пуст") << "\n";
    // std::cout << *p;  // скомпилируется, но это разыменование nullptr — UB
    return 0;
}
