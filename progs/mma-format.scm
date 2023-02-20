;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : mma-format.scm
;; DESCRIPTION : Format of plugin mma
;; COPYRIGHT   : (C) 2023 Hammer Hu
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(texmacs-module (mma-format))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mma source files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-format mma
  (:name "MMA Source Code")
  (:suffix "wls"))

(define (texmacs->mma x . opts)
  (texmacs->verbatim x (acons "texmacs->verbatim:encoding" "SourceCode" '())))

(define (mma->texmacs x . opts)
  (verbatim->texmacs x (acons "verbatim->texmacs:encoding" "SourceCode" '())))

(define (mma-snippet->texmacs x . opts)
  (verbatim-snippet->texmacs x (acons "verbatim->texmacs:encoding" "SourceCode" '())))

(converter texmacs-tree mma-document
  (:function texmacs->mma))

(converter mma-document texmacs-tree
  (:function mma->texmacs))

(converter texmacs-tree mma-snippet
  (:function texmacs->mma))

(converter mma-snippet texmacs-tree
  (:function mma-snippet->texmacs))

