class APPLICATION
create make
feature
    make
        local
            a: ACCOUNT
        do
            create a.make
            a.deposit (10)
            io.put_integer (a.balance)
            io.put_new_line
            -- Enable this call to test the precondition:
            -- a.deposit (-1)
        end
end
