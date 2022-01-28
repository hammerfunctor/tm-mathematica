
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : init-mma.scm
;; DESCRIPTION : Initialize the mma plugin
;; COPYRIGHT   : (C) 2021 Hammer Hu
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (mma-serialize lan t)
    (with u (pre-serialize lan t)
      (with s (texmacs->code (stree->tree u) "SourceCode")
;;        (string-append s "\n<EOF>\n"))))
        (string-append s "\n"))))


(define (mma-entry)
  (system-url->string
    (if (url-exists? "$TEXMACS_HOME_PATH/plugins/mma/wolfram/tmWolfram.wls")
       "$TEXMACS_HOME_PATH/plugins/mma/wolfram/tmWolfram.wls"
       "$TEXMACS_PATH/plugins/mma/wolfram/tmWolfram.wls")))

(define (mma-launcher)
  (with boot (raw-quote (mma-entry))
    (if (url-exists-in-path? "wolframscript")
        (string-append "wolframscript " boot)
        (string-append "wolframscript " boot))))

(plugin-configure mma
  (:winpath "mma" "bin")
  (:require (url-exists-in-path? "wolframscript"))
  (:serializer ,mma-serialize)
  (:launch ,(mma-launcher))
  (:tab-completion #t)
  (:session "mma"))

(when (supports-mma?)
  (plugin-input-converters mma))
