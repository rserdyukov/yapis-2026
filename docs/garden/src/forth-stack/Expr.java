// Во что javac компилирует (a + b) * c: байткод стековой JVM.
public class Expr {
    static int f(int a, int b, int c) {
        return (a + b) * c;
    }

    public static void main(String[] args) {
        System.out.println(f(2, 3, 4));
    }
}
