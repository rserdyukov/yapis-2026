"""«Рабочий падает, надзиратель перезапускает» на multiprocessing.

Тот же сценарий, что supervisor_loop.erl: задания [4, 1, 0, 5, 0, 2],
на 0 рабочий падает с ZeroDivisionError, родитель видит exitcode и
запускает нового рабочего. Порядок детерминирован: родитель ждёт ответа
или конца канала (EOF) после каждого задания, таймеров нет.
"""
import multiprocessing as mp
import sys

MAX_RESTARTS = 3


# --8<-- [start:worker]
def worker(conn):
    handled = 0                      # состояние процесса; при падении теряется
    while True:
        x = conn.recv()
        conn.send((100 // x, handled + 1))   # x == 0 -> ZeroDivisionError, процесс умирает
        handled += 1
# --8<-- [end:worker]


# --8<-- [start:supervisor]
def start_worker():
    parent_end, child_end = mp.Pipe()
    proc = mp.Process(target=worker, args=(child_end,), daemon=True)
    proc.start()
    child_end.close()                # иначе recv() не увидит EOF после смерти рабочего
    return proc, parent_end


def supervise(jobs):
    proc, conn = start_worker()
    restarts = 0
    for x in jobs:
        conn.send(x)
        try:
            result, handled = conn.recv()
            print(f"job {x} -> {result} (handled by this worker: {handled})")
        except EOFError:             # аналог сообщения {'EXIT', Pid, Reason}
            proc.join()
            if restarts == MAX_RESTARTS:
                print(f"job {x}: too many restarts, giving up")
                return
            restarts += 1
            print(f"job {x}: worker exited with code {proc.exitcode}; restart {restarts}")
            proc, conn = start_worker()
    print(f"done: restarts = {restarts}")
# --8<-- [end:supervisor]


if __name__ == "__main__":
    sys.stdout.reconfigure(line_buffering=True)   # не перемешивать с stderr при выводе в канал
    supervise([4, 1, 0, 5, 0, 2])
