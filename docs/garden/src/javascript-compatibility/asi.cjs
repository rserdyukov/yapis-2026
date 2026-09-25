// Автоматическая вставка точки с запятой (ASI): перевод строки после return.

function config() {
  return
  {
    port: 80
  }
}

function configFixed() {
  return {
    port: 80,
  };
}

console.log(config(), configFixed());

// Обратная ловушка: перевод строки НЕ завершает оператор,
// если следующая строка начинается с «(» или «[».
const a = 1
const b = a
;[10, 20].forEach((x) => console.log(b + x))  // без ведущей «;» было бы a[10, 20]
