class ACCOUNT
create make
feature
    balance: INTEGER

    make
        do
            balance := 0
        ensure
            empty: balance = 0
        end

    deposit (amount: INTEGER)
        require
            positive: amount > 0
        do
            balance := balance + amount
        ensure
            credited: balance = old balance + amount
        end
invariant
    non_negative: balance >= 0
end
