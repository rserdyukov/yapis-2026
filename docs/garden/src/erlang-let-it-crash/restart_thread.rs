// Rust: panic изолирован в потоке, join() возвращает Err, «надзиратель» перезапускает.
// Запуск: rustc -O restart_thread.rs && ./restart_thread
use std::sync::mpsc;
use std::thread;

// --8<-- [start:main]
fn spawn_worker() -> (mpsc::Sender<i32>, mpsc::Receiver<i32>, thread::JoinHandle<()>) {
    let (job_tx, job_rx) = mpsc::channel::<i32>();
    let (res_tx, res_rx) = mpsc::channel::<i32>();
    let handle = thread::spawn(move || {
        for x in job_rx {
            res_tx.send(100 / x).unwrap(); // x == 0 -> panic: attempt to divide by zero
        }
    });
    (job_tx, res_rx, handle)
}

fn main() {
    let (mut tx, mut rx, mut handle) = spawn_worker();
    let mut restarts = 0;
    for x in [4, 1, 0, 5, 0, 2] {
        tx.send(x).unwrap();
        match rx.recv() {
            Ok(r) => println!("job {x} -> {r}"),
            Err(_) => {
                // канал закрыт: поток завершился паникой
                let died = handle.join().is_err();
                restarts += 1;
                println!("job {x}: worker panicked = {died}; restart {restarts}");
                (tx, rx, handle) = spawn_worker();
            }
        }
    }
    println!("done: restarts = {restarts}");
}
// --8<-- [end:main]
