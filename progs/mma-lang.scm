;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : mma-lang.scm
;; DESCRIPTION : Wolfram language
;; COPYRIGHT   : (C) 2022 Hammer Hu
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(texmacs-module (mma-lang)
  (:use (prog default-lang)))

(tm-define (parser-feature lan key)
  (:require (and (== lan "mma") (== key "keyword")))
  `(,(string->symbol key)
    (constant
     "None" "True" "False" "$Failed" "List" "Hold" "HoldForm" "FullForm" "If" "While"
     "Map" "Module" "Do")))

(tm-define (parser-feature lan key)
  (:require (and (== lan "mma") (== key "operator")))
  `(,(string->symbol key)
    (operator
     "&&" "||" "!"
     "+" "-" "/" "^"
     "&" "@" "@@" "/@"
     ">" "<" ">=" "<=" "==" "!="
     "=" ":="
     ">>" "<<"
     "<>")
    (operator_special "_")
    (operator_decoration "#")
    (operator_openclose "{" "[" "(" ")" "]" "}")))

(define (mma-number-suffix)
  `(suffix
    (imaginary "I")))

(tm-define (parser-feature lan key)
  (:require (and (== lan "mma") (== key "number")))
  `(,(string->symbol key)
    ;; (bool_features
    ;;  "prefix_0x" "prefix_0b" "prefix_0o" "no_suffix_with_box"
    ;;  "sci_notation")
    ,(mma-number-suffix)
    ;; (separator "_")
    ))

(tm-define (parser-feature lan key)
  (:require (and (== lan "mma") (== key "string")))
  `(,(string->symbol key)
    ;; (bool_features
    ;;  "hex_with_8_bits" "hex_with_16_bits"
    ;;  "hex_with_32_bits" "octal_upto_3_digits")
    (escape_sequences "\\." "\\" "\"" "'" "a" "b" "f" "n" "r" "t" "v" "newline")
    ))

;; (tm-define (parser-feature lan key)
;;   (:require (and (== lan "mma") (== key "comment")))
;;   `(,(string->symbol key)
;;     (inline "#")))


(define (notify-mma-syntax var val)
  (syntax-read-preferences "mma"))

(define-preferences
  ("syntax:mma:none" "red" notify-mma-syntax)
  ("syntax:mma:comment" "brown" notify-mma-syntax)
  ("syntax:mma:error" "dark red" notify-mma-syntax)
  ("syntax:mma:constant" "#4040c0" notify-mma-syntax)
  ("syntax:mma:constant_number" "#4040c0" notify-mma-syntax)
  ("syntax:mma:constant_string" "dark grey" notify-mma-syntax)
  ("syntax:mma:constant_char" "#333333" notify-mma-syntax)
  ("syntax:mma:declare_function" "#0000c0" notify-mma-syntax)
  ("syntax:mma:declare_type" "#0000c0" notify-mma-syntax)
  ("syntax:mma:operator" "#8b008b" notify-mma-syntax)
  ("syntax:mma:operator_openclose" "#B02020" notify-mma-syntax)
  ("syntax:mma:operator_decoration" "#88888" notify-mma-syntax)
  ("syntax:mma:operator_special" "orange" notify-mma-syntax)
  ("syntax:mma:keyword" "#309090" notify-mma-syntax)
  ("syntax:mma:keyword_conditional" "#309090" notify-mma-syntax)
  ("syntax:mma:keyword_control" "#309090" notify-mma-syntax)
  )
