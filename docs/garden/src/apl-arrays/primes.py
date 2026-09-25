# Те же простые числа без нотации массивов: явные циклы Python.
N = 50
R = list(range(2, N + 1))                     # R←1↓⍳N
products = {a * b for a in R for b in R}      # R∘.×R (как множество)
mask = [0 if r in products else 1 for r in R] # ~R∊…
print([r for r, keep in zip(R, mask) if keep])  # mask/R

V = [3, 1, 4, 1, 5, 9, 2, 6]
print(sum(V) / len(V))                        # (+/V)÷≢V
