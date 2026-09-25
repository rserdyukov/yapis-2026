// Rc<RefCell<T>>: разделяемое владение + проверка заимствований во время выполнения.
use std::cell::RefCell;
use std::rc::Rc;

fn main() {
    let shared = Rc::new(RefCell::new(vec![1, 2, 3]));
    let other = Rc::clone(&shared); // два владельца одного вектора
    println!("владельцев: {}", Rc::strong_count(&shared));

    other.borrow_mut().push(4); // временное &mut, сразу отпускается
    println!("{:?}", shared.borrow());

    // Проверку «один писатель» теперь делает RefCell, а не компилятор.
    let ok = shared.try_borrow_mut().is_ok();
    println!("try_borrow_mut без конфликтов: {ok}");

    let _guard = shared.borrow_mut(); // первое исключительное заимствование живо
    println!("try_borrow_mut при живом guard: {:?}", other.try_borrow_mut().err());
    let _second = other.borrow_mut(); // второе — паника во время выполнения
    println!("сюда не дойдём");
}
