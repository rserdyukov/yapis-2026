(import (scheme base) (scheme write))

(define-syntax swap!
  (syntax-rules ()
    ((_ a b)
     (let ((tmp a))
       (set! a b)
       (set! b tmp)))))

(let ((tmp 1) (x 2))
  (swap! tmp x)
  (write (list tmp x)) (newline))
