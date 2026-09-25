identification division.
program-id. decimal-demo.
data division.
working-storage section.
01 amount pic 9(3)v9 value 12.3.
01 shown pic 999.9.
procedure division.
    move amount to shown
    display shown
    add 0.1 to amount
    move amount to shown
    display shown
    add 1000 to amount
        on size error display "overflow"
    end-add
    stop run.
