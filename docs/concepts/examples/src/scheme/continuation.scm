(import (scheme base) (scheme write))

;; Re-enter the same continuation twice; phase lives outside it.
(let ((saved #f) (phase 0))
  (let ((answer (+ 10 (call-with-current-continuation
                       (lambda (k) (set! saved k) 1)))))
    (display answer) (newline)
    (cond ((= phase 0) (set! phase 1) (saved 2))
          ((= phase 1) (set! phase 2) (saved 3)))))
