#include <stdio.h>

/* Препроцессор подставляет токены, ничего не зная о выражениях и именах. */
// --8<-- [start:defs]
#define SQUARE(x) x * x
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define PRINT_TWICE(e)                                                         \
    do {                                                                       \
        int i;                                                                 \
        for (i = 0; i < 2; i++)                                                \
            printf("  %d\n", (e));                                             \
    } while (0)
// --8<-- [end:defs]

int main(void) {
    // --8<-- [start:use]
    /* 1. Приоритет: раскрывается в 1 + 2 * 1 + 2. */
    printf("SQUARE(1 + 2) = %d\n", SQUARE(1 + 2));

    /* 2. Двойное вычисление: i++ выполняется дважды. */
    int i = 3, j = 2;
    int m = MAX(i++, j);
    printf("MAX(i++, j) = %d, i = %d\n", m, i);

    /* 3. Захват имени: i в аргументе связывается с i внутри макроса. */
    i = 7;
    printf("PRINT_TWICE(i * 10):\n");
    PRINT_TWICE(i * 10);
    // --8<-- [end:use]
    return 0;
}
