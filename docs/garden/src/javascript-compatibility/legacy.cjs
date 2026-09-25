// Мелкие наследия, которые нельзя исправить.

// Месяцы Date нумеруются с 0 (унаследовано от java.util.Date).
const d = new Date(2026, 8, 25);
console.log(d.getMonth(), d.toDateString());

// Дыры в массивах: элемент отсутствует, а не равен undefined.
const holes = [1, , 3];
console.log(holes.length, 1 in holes, holes.map((x) => x * 10), holes.indexOf(undefined), holes.includes(undefined));

// arguments в нестрогой функции связан с параметрами, в строгой — нет.
function sloppyArgs(a) { arguments[0] = 99; return a; }
function strictArgs(a) { "use strict"; arguments[0] = 99; return a; }
console.log(sloppyArgs(1), strictArgs(1));

// Новые возможности добавляются, старые остаются: flat появился в ES2019,
// потому что имя flatten было занято библиотекой MooTools на реальных сайтах.
console.log([1, [2, [3]]].flat(), typeof [].flatten, typeof [].contains, typeof [].includes);
