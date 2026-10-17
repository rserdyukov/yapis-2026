"""Модульные тесты анализатора Mini."""
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def run(name):
    return subprocess.run([sys.executable, str(ROOT / "compiler" / "mini.py"), str(ROOT / "examples" / name)],
                          capture_output=True, text=True).returncode


class MiniTest(unittest.TestCase):
    def test_correct_examples(self):
        for name in ("1.txt", "2.txt", "3.txt"):
            self.assertEqual(run(name), 0, name)

    def test_error_examples(self):
        for p in sorted((ROOT / "examples").glob("error-*.txt")):
            self.assertNotEqual(run(p.name), 0, p.name)


if __name__ == "__main__":
    unittest.main()
