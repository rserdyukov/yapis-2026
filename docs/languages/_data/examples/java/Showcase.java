import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

/**
 * Пример-витрина: Java 21.
 *
 * Одна программа, в которой прокомментированы конструкции, соответствующие
 * концепциям каталога. Маркеры {@code --8<--} размечают секции для сайта и не
 * влияют на компиляцию. Собрать: {@code javac Showcase.java && java Showcase}.
 */
public class Showcase {

    // --8<-- [start:req-8-2]
    // 8.2. Глобальных переменных нет: любая переменная — член класса или
    // локальная. Эквивалент глобального состояния — статическое поле.
    static int counter = 0;

    static void bump() {
        counter++;
    }
    // --8<-- [end:req-8-2]

    // --8<-- [start:variants-9]
    // 9. Подпрограммы объявляются только как методы класса; вложенных методов
    // нет. Обход — лямбда или локальный класс внутри метода.
    static int outer(int x) {
        java.util.function.IntUnaryOperator inner = y -> x + y; // лямбда видит x
        return inner.applyAsInt(1);
    }
    // --8<-- [end:variants-9]

    // --8<-- [start:variants-7]
    // 7. Перегрузка методов есть: выбор по статическим типам аргументов.
    static String describe(int value) {
        return "целое " + value;
    }

    static String describe(double value) {
        return "дробное " + value;
    }
    // --8<-- [end:variants-7]

    // --8<-- [start:variants-8]
    // 8. Передача параметров — всегда по значению (JLS 8.4.1), но значение
    // ссылочного типа — это ссылка на объект: изменение объекта видно
    // вызывающему, перепривязка параметра — нет.
    static void appendAndRebind(List<Integer> items, int n) {
        items.add(n);              // видно снаружи: тот же объект
        n = n + 1;                 // не видно: копия примитива
        items = new ArrayList<>(); // не видно: локальная ссылка
    }
    // --8<-- [end:variants-8]

    // --8<-- [start:req-4]
    // 4. Ввод-вывод — классы стандартной библиотеки: System.out для вывода,
    // Scanner (или BufferedReader) для ввода. Встроенных функций нет.
    static int readInt(Scanner in) {
        return in.nextInt();
    }
    // --8<-- [end:req-4]

    public static void main(String[] args) {
        // --8<-- [start:variants-1]
        // 1. Объявление явное — тип перед именем. С версии 10 для локальных
        // переменных допустим `var`: тип выводится, но объявление остаётся.
        int total = 0;
        var name = "ЯПИС"; // String
        // --8<-- [end:variants-1]

        // --8<-- [start:variants-2]
        // 2. Преобразование типов явное — оператор приведения `(int) x`;
        // неявное — только расширяющее (int → long → double) и boxing.
        int count = Integer.parseInt("42");
        double ratio = count / 5.0;   // int → double неявно (расширение)
        int truncated = (int) ratio;  // double → int только явно
        // --8<-- [end:variants-2]

        // --8<-- [start:variants-3]
        // 3. Присваивание одиночное; `a = b = 0` — цепочка одиночных,
        // множественного `a, b = c, d` нет.
        int a, b;
        a = b = 1;
        int tmp = a;
        a = b + 1;
        b = tmp;
        // --8<-- [end:variants-3]

        // --8<-- [start:variants-4]
        // 4. Область видимости ограничивают и методы, и блоки `{ }`.
        if (count > 0) {
            String insideBlock = "видна только здесь";
            System.out.println(insideBlock);
        }
        // System.out.println(insideBlock); // ошибка компиляции
        // --8<-- [end:variants-4]

        // --8<-- [start:variants-5]
        // 5. Маркер блока явный — фигурные скобки; для одного оператора
        // их можно опустить, но это отдельный оператор, а не блок.
        for (int i = 0; i < 3; i++) {
            total += i;
        }
        // --8<-- [end:variants-5]

        // --8<-- [start:variants-6]
        // 6. if / else if / else и многовариантный switch. С версии 14
        // switch — также выражение со стрелочными ветками без fall-through;
        // с версии 21 — сопоставление с образцом по типам.
        String size;
        if (total > 100) {
            size = "много";
        } else if (total > 10) {
            size = "средне";
        } else {
            size = "мало";
        }
        String label = switch (a) {
            case 1 -> "единица";
            case 2 -> "двойка";
            default -> "что-то другое";
        };
        Object obj = ratio;
        String kind = switch (obj) {
            case Integer i -> "Integer " + i;
            case Double d -> "Double " + d;
            default -> "другой тип";
        };
        System.out.println(size + ", " + label + ", " + kind);
        // --8<-- [end:variants-6]

        // --8<-- [start:req-7-3]
        // 7.3. Цикл for в двух формах: счётный (в стиле C) и по коллекции.
        for (int i = 0; i < 10; i += 2) {
            System.out.print(i + " ");
        }
        for (char ch : name.toCharArray()) {
            System.out.print(ch + " ");
        }
        System.out.println();
        // --8<-- [end:req-7-3]

        // --8<-- [start:req-7-2-until]
        // 7.2. Цикла until нет; эквивалент — while с отрицанием условия.
        int n = 0;
        while (!(n >= 3)) {
            n++;
        }
        // --8<-- [end:req-7-2-until]

        // --8<-- [start:req-7-2-do-while]
        // Цикл do-while есть: тело выполняется хотя бы раз.
        do {
            n--;
        } while (n > 0);
        // --8<-- [end:req-7-2-do-while]

        System.out.println(describe(count) + ", " + describe(ratio) + ", " + outer(41) + ", " + truncated);
        List<Integer> items = new ArrayList<>();
        appendAndRebind(items, 5);
        System.out.println(items); // [5]
        bump();
        System.out.println(counter + " " + b);

        if (args.length > 0) {
            try (Scanner in = new Scanner(System.in)) {
                System.out.println(readInt(in));
            }
        }
    }
}
