
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

(use-modules (dynamic session-edit) (dynamic program-edit))

(define (mma-serialize lan t)
  (with u (pre-serialize lan t)
    (with s (texmacs->code (stree->tree u) "SourceCode")
      (string-append s "\nEndOfFile\n"))))
;;        (string-append s "\n"))))


(define (mma-entry)
  (system-url->string
   (if (url-exists? "$TEXMACS_HOME_PATH/plugins/mma/wolfram/tmWolfram.wls")
       "$TEXMACS_HOME_PATH/plugins/mma/wolfram/tmWolfram.wls"
       "$TEXMACS_PATH/plugins/mma/wolfram/tmWolfram.wls")))

(define (mma-launcher)
  (with boot (raw-quote (mma-entry))
    (if (url-exists-in-path? "wolframscript")
        (string-append "wolframscript -f " boot)
        (string-append "wolfram -script " boot))))

(plugin-configure mma
  (:winpath "wolframscript" ".")
  (:require (or (url-exists-in-path? "wolframscript")
                (url-exists-in-path? "wolfram")))
  (:serializer ,mma-serialize)
  (:launch ,(mma-launcher))
  (:tab-completion #t)
  (:session "mma")
  (:script "mma"))

(texmacs-modes
 (in-mma% (== (get-env "prog-language") "mma"))
 (in-prog-mma% #t in-prog% in-mma%))

;; to complete
(lazy-keyboard (mma-edit) in-prog-mma?)

(when (supports-mma?)
  ;; (import-from (mma-menus))
  ;; (lazy-input-converter (mma-input) mma)
  (lazy-keyboard (mma-kbd) in-mma?)
  ;; (plugin-approx-command-set! "mma" "") ; ?
  )

