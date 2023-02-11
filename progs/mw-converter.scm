;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : mw-converter.scm
;; DESCRIPTION : Convert string snippet in a math env to legal wolfram expression
;; COPYRIGHT   : (C) 2022 Hammer Hu
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(texmacs-module (mw-converter)
  (:use (ice-9 regex))
  )

(define mw-symbol-map-table (make-hash-table 30))
(hashq-set! mw-symbol-map-table 'sin (make-regexp "sin\\s*\\("))
(hashq-set! mw-symbol-map-table 'cos (make-regexp "cos\\s*\\("))
(hashq-set! mw-symbol-map-table 'tan (make-regexp "tan\\s*\\("))
(hashq-set! mw-symbol-map-table 'cot (make-regexp "cot\\s*\\("))
(hashq-set! mw-symbol-map-table 'sec (make-regexp "sec\\s*\\("))
(hashq-set! mw-symbol-map-table 'csc (make-regexp "csc\\s*\\("))
(hashq-set! mw-symbol-map-table 'exp (make-regexp "exp\\s*\\("))
(hashq-set! mw-symbol-map-table 'log (make-regexp "log\\s*\\("))


(define (find-balanced-br s idx br ibr level)
  ;; (display idx)
  ;; (display "\n")
  (cond ((== level 0) (- idx 1))
        ((>= idx (string-length s)) -1)
        ((== (string-ref s idx) br) (find-balanced-br s (+ idx 1) br ibr (+ level 1)))
        ((== (string-ref s idx) ibr) (find-balanced-br s (+ idx 1) br ibr (- level 1)))
        (else (find-balanced-br s (+ idx 1) br ibr level))))

;; (string-replace "sin(x)/x" "Sin[" 0 4)
(define (mw-map-single-param-func key funcname)
  (lambda (s)
    (let ((matched (regexp-exec (hashq-ref mw-symbol-map-table key) s)))
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

(define mw-symbol-map-funcs
  (list
   (mw-map-single-param-func 'sin "Sin")
   (mw-map-single-param-func 'cos "Cos")
   (mw-map-single-param-func 'tan "Tan")
   (mw-map-single-param-func 'cot "Cot")
   (mw-map-single-param-func 'sec "Sec")
   (mw-map-single-param-func 'csc "Csc")
   (mw-map-single-param-func 'exp "Exp")
   (mw-map-single-param-func 'log "Log")
   ))

(define (mw-symbol-map s)
  (define (mw-symbol-map-rec restf s)
    (if (null? restf)
        s
        ;; recursive do the map
        (let ((mapped-string ((car restf) s)))
          ;; (display mapped-string)
          (if (string=? s mapped-string)
              (mw-symbol-map-rec (cdr restf) s)
              (mw-symbol-map-rec restf mapped-string)))))
  (mw-symbol-map-rec mw-symbol-map-funcs s))

(tm-define (mw-map-math lan wrapped rest)
  (cond ((null? rest) wrapped)
        ((list? rest)
         (let ((firstel (car rest))) ;; depend on the first element
           (cond ((== firstel 'math)
                  ;; map the whole list: `rest'
                  (let* ((mathstring (plugin-math-input (list 'tuple lan (cadr rest))))
                         (mapped-string (mw-symbol-map mathstring)))
                    ;; (display mathstring)
                    ;; (display mapped-string)
                    mapped-string))
                 ((func? firstel 'math 1)
                  ;; map the first element of `rest': `firstel'
                  (let* ((mathstring (plugin-math-input (list 'tuple lan (cadr firstel))))
                         (mapped-string (mw-symbol-map mathstring)))
                    ;; (display mathstring)
                    ;; (display mapped-string)
                    (mw-map-math lan (append wrapped (list mapped-string)) (cdr rest))))
                 (else (mw-map-math lan (append wrapped (list firstel)) (cdr rest))))))
        (else rest)))


