;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : mma-math-converter.scm
;; DESCRIPTION : Convert string snippet in a math env
;; COPYRIGHT   : (C) 2022 Hammer Hu
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(texmacs-module (mma-math-converter)
  (:use (ice-9 regex))
  )

;; (use-modules (ice-9 regex))

(define mma-symbol-map-table (make-hash-table 30))
(hashq-set! mma-symbol-map-table 'sin (make-regexp "sin\\s*\\("))
(hashq-set! mma-symbol-map-table 'cos (make-regexp "cos\\s*\\("))
(hashq-set! mma-symbol-map-table 'tan (make-regexp "tan\\s*\\("))
(hashq-set! mma-symbol-map-table 'cot (make-regexp "cot\\s*\\("))
(hashq-set! mma-symbol-map-table 'sec (make-regexp "sec\\s*\\("))
(hashq-set! mma-symbol-map-table 'csc (make-regexp "csc\\s*\\("))
(hashq-set! mma-symbol-map-table 'exp (make-regexp "exp\\s*\\("))
(hashq-set! mma-symbol-map-table 'log (make-regexp "log\\s*\\("))


(define (find-balanced-br s idx br ibr level)
  ;; (display idx)
  ;; (display "\n")
  (cond ((== level 0) (- idx 1))
        ((>= idx (string-length s)) -1)
        ((== (string-ref s idx) br) (find-balanced-br s (+ idx 1) br ibr (+ level 1)))
        ((== (string-ref s idx) ibr) (find-balanced-br s (+ idx 1) br ibr (- level 1)))
        (else (find-balanced-br s (+ idx 1) br ibr level))))

;; (string-replace "sin(x)/x" "Sin[" 0 4)
(define (mma-map-single-param-func key funcname)
  (lambda (s)
    (let ((matched (regexp-exec (hashq-ref mma-symbol-map-table key) s)))
      (if matched
          (let* ((start (match:start matched))
                 (end (match:end matched))
                 (closed-br (find-balanced-br s end #\( #\) 1)))
            ;; (display closed-br)
            (if (> closed-br 0)
                (string-append (string-take s start)
                               funcname "["
                               (substring s end closed-br) "]"
                               (string-drop s (+ closed-br 1)))
                ;; doesn't work due to texmacs' hack
                ;; (string-replace
                ;;  (string-replace s "]" closed-br (+ closed-br 1))
                ;;  (string-append funcname "[") start end)
                s))
          s))))

(define mma-symbol-map-funcs
  (list
   (mma-map-single-param-func 'sin "Sin")
   (mma-map-single-param-func 'cos "Cos")
   (mma-map-single-param-func 'tan "Tan")
   (mma-map-single-param-func 'cot "Cot")
   (mma-map-single-param-func 'sec "Sec")
   (mma-map-single-param-func 'csc "Csc")
   (mma-map-single-param-func 'exp "Exp")
   (mma-map-single-param-func 'log "Log")
   ))

(define (mma-symbol-map s)
  (define (mma-symbol-map-rec restf s)
    (if (null? restf)
        s
        ;; recursive do the map
        (let ((mapped-string ((car restf) s)))
          ;; (display mapped-string)
          (if (string=? s mapped-string)
              (mma-symbol-map-rec (cdr restf) s)
              (mma-symbol-map-rec restf mapped-string)))))
  (mma-symbol-map-rec mma-symbol-map-funcs s))

(tm-define (mma-map-math lan wrapped rest)
  (cond ((null? rest) wrapped)
        ((list? rest)
         (let ((firstel (car rest))) ;; depend on the first element
           (cond ((== firstel 'math)
                  ;; map the whole list: `rest'
                  (let* ((mathstring (plugin-math-input (list 'tuple lan (cadr rest))))
                         (mapped-string (mma-symbol-map mathstring)))
                    ;; (display mathstring)
                    ;; (display mapped-string)
                    mapped-string))
                 ((func? firstel 'math 1)
                  ;; map the first element of `rest': `firstel'
                  (let* ((mathstring (plugin-math-input (list 'tuple lan (cadr firstel))))
                         (mapped-string (mma-symbol-map mathstring)))
                    ;; (display mathstring)
                    ;; (display mapped-string)
                    (mma-map-math lan (append wrapped (list mapped-string)) (cdr rest))))
                 (else (mma-map-math lan (append wrapped (list firstel)) (cdr rest))))))
        (else rest)))


