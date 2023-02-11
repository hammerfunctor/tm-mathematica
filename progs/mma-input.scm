
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : mma-input.scm
;; DESCRIPTION : mma input converters
;; COPYRIGHT   : (C) 2022 Hammer Hu
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(texmacs-module (mma-input)
  (:use (utils plugins plugin-convert)))

(define (mma-input-sqrt args)
  (if (= (length args) 1)
      (begin
        (display "Sqrt[")
        (plugin-input (car args))
        (display "]"))
      (begin
        (display "(")
        (plugin-input (car args))
        (display ")^(1/(")
        (plugin-input (cadr args))
        (display "))"))))

;; This technique doesn't work for sin, cos, etc. since they are not
;; structure conponents, just plain text
(plugin-input-converters mma
  (sqrt mma-input-sqrt)

  ("<infty>" "Infinity")
  ("<mathe>" "E")
  ("<mathi>" "I")
  ("<pi>" "Pi")
  ("<assign>" " := ")
  ("<hbar>" "<#210F>") ;; literal ℏ will produce messy code
  ;; ("<in>" "<#2208>") ;; ∈, correct default
  ;; ("<bbb-R>" "Reals") ;; doesn't work
  )
