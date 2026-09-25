template <typename T>
T max_of(T a, T b) {
    return a > b ? a : b;
}

struct Point {
    int x, y;
};

int main() {
    // Ограничения на T не записаны: ошибка всплывает внутри тела шаблона.
    max_of(Point{1, 2}, Point{3, 4});
}
