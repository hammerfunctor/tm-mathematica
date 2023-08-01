
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

;; Redefinition of plugin-input-converters make `executable-fold'
;; fail to work. So I decide turn to text replacement after texmacs
;; has done its work.

(texmacs-module (mma-input)
  (:use (convert rewrite tmtm-brackets)))

;;(display* "woshi")

;; dirty hack
;;(tm-define (plugin-preprocess name ses t opts) t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; conversion of strings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (string-find-char s i n c)
  (cond ((>= i n) n)
        ((== (string-ref s i) c) i)
        (else (string-find-char s (+ i 1) n c))))

(define (string-find-end s i n pred)
  (cond ((>= i n) n)
        ((not (pred (string-ref s i))) i)
        (else (string-find-end s (+ i 1) n pred))))

(define (string->tmtokens s i n)
  (cond ((>= i n) '())
        ((== (string-ref s i) #\<)
         (let ((j (min n (+ (string-find-char s i n #\>) 1))))
           (cons (substring s i j) (string->tmtokens s j n))))
        ((char-alphabetic? (string-ref s i))
         (let ((j (string-find-end s i n char-alphabetic?)))
           (cons (substring s i j) (string->tmtokens s j n))))
        ((char-numeric? (string-ref s i))
         (let ((j (string-find-end s i n char-numeric?)))
           (cons (substring s i j) (string->tmtokens s j n))))
        (else (cons (substring s i (+ 1 i))
                    (string->tmtokens s (+ 1 i) n)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; conversion of other nodes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (plugin-input-with args)
  (if (null? (cdr args))
      (plugin-input (car args))
      (plugin-input-with (cdr args))))

(define (plugin-input-concat-big op args)
  (let* ((i (list-find-index args (lambda (x) (== x '(big ".")))))
         (head (if i (sublist args 0 i) args))
         (tail (if i (sublist args (+ i 1) (length args)) '()))
         (bigop `(big-around ,(small-bracket op) (concat ,@head))))
    (plugin-input `(concat ,bigop ,@tail))))

(define (plugin-input-concat args)
  (cond ((null? args) (noop))
        ((and (func? (car args) 'big) (nnull? (cdr args)))
         (plugin-input-concat-big (car args) (cdr args)))
        (else
         (plugin-input (car args))
         (plugin-input-concat (cdr args)))))

(define (plugin-input-math args)
  (plugin-input (car args)))

(define (plugin-input-frac args)
  (display "(")
  (plugin-input-arg (car args))
  (display "/")
  (plugin-input-arg (cadr args))
  (display ")"))

(define (plugin-input-sqrt args)
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

(define (plugin-input-rsub args)
  (display "[")
  (plugin-input (car args))
  (display "]"))

(define (plugin-input-rsup args)
  (display "^")
  (plugin-input-arg (car args)))

(define (plugin-input-around args)
  (plugin-input (tree-downgrade-brackets (cons 'around args) #f #t)))

(define (plugin-input-around* args)
  (plugin-input (tree-downgrade-brackets (cons 'around* args) #f #t)))

(define (plugin-input-big-around args)
  (let* ((b `(big-around ,@args))
         (name (big-name b))
         (sub (big-subscript b))
         (sup (big-supscript b))
         (body (big-body b)))
    (display name)
    (display "(")
    (when sub
      (plugin-input sub)
      (display ","))
    (when (and sub sup)
      (plugin-input sup)
      (display ","))
    (plugin-input body)
    (display ")")))

(define (plugin-input-large args)
  (display (car args)))

(define (plugin-input-script-assign args)
  (display ":="))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Conversion of matrices
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (plugin-input-descend-last args)
  (if (null? (cdr args))
      (plugin-input (car args))
      (plugin-input-descend-last (cdr args))))

(define (plugin-input-det args)
  (display "matdet(")
  (plugin-input-descend-last args)
  (display ")"))

(define (rewrite-cell c)
  (if (and (list? c) (== (car c) 'cell)) (cadr c) c))

(define (rewrite-row r)
  (if (null? r) r (cons (rewrite-cell (car r)) (rewrite-row (cdr r)))))

(define (rewrite-table t)
  (if (null? t) t (cons (rewrite-row (cdar t)) (rewrite-table (cdr t)))))

(define (plugin-input-row r)
  (if (null? (cdr r))
      (plugin-input (car r))
      (begin
        (plugin-input (car r))
        (display ", ")
        (plugin-input-row (cdr r)))))

(define (plugin-input-var-rows t)
  (if (nnull? t)
      (begin
        (display "; ")
        (plugin-input-row (car t))
        (plugin-input-var-rows (cdr t)))))

(define (plugin-input-rows t)
  (display "[")
  (plugin-input-row (car t))
  (plugin-input-var-rows (cdr t))
  (display "]"))

(define (plugin-input-table args)
  (let ((t (rewrite-table args)))
    (plugin-input (cons 'rows t))))



;; This technique doesn't work for sin, cos, etc. since they are not
;; structure conponents, just plain text
(plugin-input-converters mma
  (with plugin-input-with)
  (concat plugin-input-concat)
  (document plugin-input-concat)
  (math plugin-input-math)
  (frac plugin-input-frac)
  (sqrt plugin-input-sqrt)
  (rsub plugin-input-rsub)
  (rsup plugin-input-rsup)
  (around plugin-input-around)
  (around* plugin-input-around*)
  (big-around plugin-input-big-around)
  (left plugin-input-large)
  (middle plugin-input-large)
  (right plugin-input-large)
  (tabular plugin-input-descend-last)
  (tabular* plugin-input-descend-last)
  (block plugin-input-descend-last)
  (block* plugin-input-descend-last)
  (matrix plugin-input-descend-last)
  (det plugin-input-det)
  (bmatrix plugin-input-descend-last)
  (tformat plugin-input-descend-last)
  (table plugin-input-table)
  (rows plugin-input-rows)
  (script-assign plugin-input-script-assign)

  ("<longequal>" "==")
  ("<assign>" ":=")
  ("<plusassign>" "+=")
  ("<minusassign>" "-=")
  ("<timesassign>" "*=")
  ("<overassign>" "/=")
  ("<lflux>" "<less><less>")
  ("<gflux>" "<gtr><gtr>")

  ("<implies>" "=<gtr>")
  ("<Rightarrow>" "=<gtr>")
  ("<equivalent>" "<less>=<gtr>")
  ("<Leftrightarrow>" "<less>=<gtr>")
  ("<neg>" "not ")
  ("<wedge>" " and ")
  ("<vee>" " or ")
  ("<neq>" "!=")
  ("<less>" "<less>")
  ("<gtr>" "<gtr>")
  ("<leq>" "<less>=")
  ("<geq>" "<gtr>=")
  ("<leqslant>" "<less>=")
  ("<geqslant>" "<gtr>=")
  ("<ll>" "<less><less>")
  ("<gg>" "<gtr><gtr>")
  ("<into>" "-<gtr>")
  ("<mapsto>" "|-<gtr>")
  ("<rightarrow>" "-<gtr>")
  ("<transtype>" ":<gtr>")

  ("<um>" "-")
  ("<upl>" "+")
  ("<times>" "*")
  ("<ast>" "*")
  ("<cdot>" "*")
  ("<ldots>" "..")
  ("<colons>" "::")
  ("<sharp>" "#")
  ("<circ>" "@")

  ("<bbb-C>" "CC")
  ("<bbb-F>" "FF")
  ("<bbb-N>" "NN")
  ("<bbb-K>" "KK")
  ("<bbb-R>" "Reals")
  ("<bbb-Q>" "QQ")
  ("<bbb-Z>" "ZZ")
  ("<mathe>" "E")
  ("<mathpi>" "Pi")
  ("<mathi>" "I")
  ("<infty>" "Infinity")

  ("<hbar>" "<#210F>") ;; literal ℏ will produce messy code
  ("<in>" "\\[Element]") ;; ∈, correct default


  ("<alpha>"      "alpha")
  ("<beta>"       "beta")
  ("<gamma>"      "gamma")
  ("<delta>"      "delta")
  ("<epsilon>"    "epsilon")
  ("<varepsilon>" "epsilon")
  ("<zeta>"       "zeta")
  ("<eta>"        "eta")
  ("<theta>"      "theta")
  ("<vartheta>"   "theta")
  ("<iota>"       "iota")
  ("<kappa>"      "kappa")
  ("<lambda>"     "lambda")
  ("<mu>"         "mu")
  ("<nu>"         "nu")
  ("<xi>"         "xi")
  ("<omicron>"    "omicron")
  ("<pi>"         "Pi")
  ("<rho>"        "rho")
  ("<varrho>"     "varrho")
  ("<sigma>"      "sigma")
  ("<varsigma>"   "sigma")
  ("<tau>"        "tau")
  ("<upsilon>"    "upsilon")
  ("<phi>"        "\\[Phi]")
  ("<varphi>"     "phi")
  ("<chi>"        "chi")
  ("<psi>"        "psi")
  ("<omega>"      "omega")

  ("<Alpha>"      "Alpha")
  ("<Beta>"       "Beta")
  ("<Gamma>"      "Gamma")
  ("<Delta>"      "Delta")
  ("<Epsilon>"    "Epsilon")
  ("<Zeta>"       "Zeta")
  ("<Eta>"        "Eta")
  ("<Theta>"      "Theta")
  ("<Iota>"       "Iota")
  ("<Kappa>"      "Kappa")
  ("<Lambda>"     "Lambda")
  ("<Mu>"         "Mu")
  ("<Nu>"         "Nu")
  ("<Xi>"         "Xi")
  ("<Omicron>"    "Omicron")
  ("<Pi>"         "Pi")
  ("<Rho>"        "Rho")
  ("<Sigma>"      "Sigma")
  ("<Tau>"        "Tau")
  ("<Upsilon>"    "Upsilon")
  ("<Phi>"        "\\[CapitalPhi]")
  ("<Chi>"        "Chi")
  ("<Psi>"        "Psi")
  ("<Omega>"      "Omega"))
