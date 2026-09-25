# NumPy-эквиваленты (NumPy в среде проверки не установлен — не запускалось).
import numpy as np

print(np.array([1, 2, 3]) + 10)          # 1 2 3+10: broadcasting скаляра
print(np.add.reduce([3, 1, 4, 1, 5]))    # +/ : ufunc.reduce
print(np.add.accumulate([1, 2, 3, 4]))   # +\ : ufunc.accumulate
print(np.multiply.outer([1, 2, 3], [10, 20, 30, 40]))   # ∘.×
R = np.arange(2, 51)
print(R[~np.isin(R, np.multiply.outer(R, R))])          # (~R∊R∘.×R)/R
