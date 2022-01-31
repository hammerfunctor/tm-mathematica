
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : init-mathematica.scm
;; DESCRIPTION : Initialize mathematica plugin
;; COPYRIGHT   : (C) 2005  Andrey Grozin
;; COPYRIGHT   : (C) 2021  Hammer Hu
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (mma-serialize lan t)
    (with u (pre-serialize lan t)
      (with s (texmacs->code (stree->tree u) "SourceCode")
        (string-append s "\0"))))

(plugin-configure mma
  (:require (url-exists-in-path? "WolframKernel"))
  (:serializer ,mma-serialize)
  (:launch "tm_mma.bin")
  (:session "Mathematica - CXX"))

(when (supports-mma?)
  (plugin-input-converters mma))
