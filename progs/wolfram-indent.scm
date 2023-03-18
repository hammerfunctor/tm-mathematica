
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : wolfram-indent.scm
;; DESCRIPTION : Indenting Wolfram programs
;; COPYRIGHT   : (C) 2022 Hammer Hu
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(texmacs-module (wolfram-indent)
  (:use (prog prog-edit)
        (utils misc tm-keywords)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; hacking standard string-bracket-find*
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (my-string-bracket-find s pos inc br ibr level)
  ;;(display* "find: pos= " pos ", level= " level "\n")
  (cond ((or (< pos 0) (>= pos (string-length s))) level)
        ((and (== level 1) (== (string-ref s pos) br))
         ;;(display* "returning at " pos "\n")
         pos)
        ((== (string-ref s pos) br)
         ;;(display* "found at " pos "\n")
         (my-string-bracket-find s (+ pos inc) inc br ibr (+ level 1)))
        ((== (string-ref s pos) ibr)
         (my-string-bracket-find s (+ pos inc) inc br ibr (- level 1)))
        (else (my-string-bracket-find s (+ pos inc) inc br ibr level))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Auto indent
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define wolfram-indenters
  '("=" ":="
    "->" ":>"
    "@" "&@" "@@" "&@@" "/@" "&/@"
    "<>"
    "+" "-" "/"
    "/." "//."
    "<" ">" "<=" ">=" "==" "!="
    "&&" "||"))

(define (standard-indent? s)
  (with indent?
      (lambda (x) (or (== s x) (string-ends? (string-trim-right s) (string-append " " x))))
    (not (not (list-find wolfram-indenters indent?)))))

(define (reference-row-bis row)
  (with s (program-row (- row 1))
    (cond ((not s) row)
	  ((standard-indent? s) (reference-row-bis (- row 1)))
	  (else row))))

(define (reference-row row)
  (let* ((r1 (program-previous-match row #\{ #\}))
	 (r2 (program-previous-match row #\( #\)))
	 (r3 (program-previous-match row #\[ #\]))
	 (rr (min r1 r2 r3)))
    (reference-row-bis rr)))

(define (compute-indentation-bis row)
  (let* ((prev (max 0 (- row 1)))
	 (s (program-row prev))
	 (i (string-get-indent s))
	 (last (- (string-length s) 1))
	 (curly (my-string-bracket-find s last -1 #\{ #\} 0))
	 (round (my-string-bracket-find s last -1 #\( #\) 0))
	 (square (my-string-bracket-find s last -1 #\[ #\] 0)))
    (if (== row 0) 0
        (list-fold (lambda (el knil)
                     (+ knil (if (car el) (cadr el) 0)))
                   i
                   (list `(,(or curly round square) ,(+ (* square 2) curly round)) ; three brackets contribute different numbers of spaces
                         `(,(standard-indent? s) 2))))

    ;; (cond ((== row 0) i)
    ;;       ((or curly round square) (+ (* square 2) curly round i)) ; three brackets contribute different numbers of spaces
    ;;       ((standard-indent? s) (+ i 2))
    ;;       (else
    ;;        (display* "row= " prev "\n")
    ;;        (display* "ref= " (reference-row prev) "\n")
    ;;        (with ref (reference-row prev)
    ;;          (string-get-indent (program-row ref)))))
    ))

(define (compute-indentation row)
  (let* ((s (program-row row))
	 (i (string-get-indent s)))
    (if (and (< i (string-length s)) (== (string-ref s i) #\}))
	(max 0 (- (compute-indentation-bis row) 2))
	(compute-indentation-bis row))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User interface for auto indent
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(tm-define (wolfram-indent)
  (:synopsis "indent current line of a wolfram program")
  (and-with doc (program-tree)
    (with i (compute-indentation (program-row-number))
      (program-set-indent i)
      (program-go-to (program-row-number) i))))
