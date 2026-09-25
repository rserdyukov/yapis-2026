;; Макрос Common Lisp получает формы (списки) и строит новую форму.
;; gensym создаёт свежие имена: вручную обеспеченная гигиена.
(defmacro my-max (a b)
  (let ((x (gensym)) (y (gensym)))
    `(let ((,x ,a) (,y ,b))
       (if (> ,x ,y) ,x ,y))))

(let ((i 3))
  (format t "~a~%" (list (my-max (incf i) 2) i)))

