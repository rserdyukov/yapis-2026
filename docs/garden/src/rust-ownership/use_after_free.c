/* Ручное управление памятью: компилятор не мешает использовать освобождённое. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    char *s = malloc(16);
    strcpy(s, "hello");
    free(s);
    printf("%s\n", s); /* use-after-free: неопределённое поведение */
    return 0;
}
