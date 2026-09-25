"""Один и тот же результат: императивный цикл в Python и один SQL-запрос.

Задача: для каждого отдела с >= 2 сотрудниками — число сотрудников и сумма
зарплат, по убыванию суммы (как в aggregate.sql).
"""
import pathlib
import sqlite3

con = sqlite3.connect(":memory:")
con.executescript(pathlib.Path(__file__).with_name("data.sql").read_text())


# --8<-- [start:imperative]
def imperative(con):
    # Как: обойти отделы, для каждого — запросить и обойти сотрудников.
    result = []
    for dept_id, title in con.execute("SELECT id, title FROM dept"):
        n, total = 0, 0
        for (salary,) in con.execute(
            "SELECT salary FROM emp WHERE dept_id = ?", (dept_id,)
        ):
            n += 1
            total += salary
        if n >= 2:
            result.append((title, n, total))
    result.sort(key=lambda row: row[2], reverse=True)
    return result
# --8<-- [end:imperative]


# --8<-- [start:declarative]
def declarative(con):
    # Что: описание результата; соединение и группировку выберет СУБД.
    return con.execute("""
        SELECT d.title, count(*), sum(e.salary)
        FROM emp AS e JOIN dept AS d ON d.id = e.dept_id
        GROUP BY d.title
        HAVING count(*) >= 2
        ORDER BY sum(e.salary) DESC
    """).fetchall()
# --8<-- [end:declarative]


# --8<-- [start:mismatch]
# Несогласованность (impedance mismatch): запрос — строка, результат — кортежи.
row = con.execute("SELECT name, dept_id FROM emp WHERE id = 5").fetchone()
print("row:", row, type(row[1]).__name__)   # SQL NULL стал Python None
try:
    con.execute("SELECT nme FROM emp")        # опечатка видна только при выполнении
except sqlite3.OperationalError as e:
    print("error:", e)
# --8<-- [end:mismatch]

print("imperative: ", imperative(con))
print("declarative:", declarative(con))
print("equal:", imperative(con) == declarative(con))
print("sqlite:", sqlite3.sqlite_version)
