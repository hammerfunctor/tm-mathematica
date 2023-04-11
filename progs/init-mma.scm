
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

(use-modules
 (dynamic session-edit)
 (dynamic program-edit)
 (mw-converter))



(texmacs-modes
 (in-mma% (== (get-env "prog-language") "mma"))
 (in-prog-mma% #t in-prog% in-mma%))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Plugin Configuration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (mma-pre-serialize-rec lan serialized this rest)
  ;;(display "mma-pre-serialize-rec: ")
  (display* this "\n")
  (let* ((this-serialized
          (cond ((func? this 'math) (mw-map-math lan '() this))
                ((func? this 'document)
                 (mma-pre-serialize-rec lan '(document) (cadr this) (cddr this)))
                (else this)))
         (serialized-new (append serialized (list this-serialized))))
    (if (null? rest)
        serialized-new
        (mma-pre-serialize-rec lan serialized-new (car rest) (cdr rest)))))

(define (mma-pre-serialize lan u)
  (cond ((func? u 'math 1)
         ;;(display* "mma-pre-serialize: 1\n" u "\n")
         (mw-map-math lan '() u))
        ((func? u 'document 1)
         ;;(display* "mma-pre-serialize: 2\n" u "\n")
         (mma-pre-serialize lan (cadr u)))
        ((func? u 'document)
         ;;(display* "mma-pre-serialize: 3\n" u "\n")
         (mma-pre-serialize-rec lan '(document) (cadr u) (cddr u)))
        (else
         ;;(display* "mma-pre-serialize: 4\nThis is not captured: " u "\n")
         u)))

;;(display (mma-pre-serialize "mma" '(document "Exp[x]]")))

(define (mma-serialize lan t)
  (with u (mma-pre-serialize lan t)
    ;;(display u)
    (with s (texmacs->code (stree->tree u) "SourceCode")
      ;; (display s)
      (string-append s "\nEndOfFile\n"))))

(define (mma-entry)
  (system-url->string
   (if (url-exists? "$TEXMACS_HOME_PATH/plugins/mma/wolfram/tmWolfram.wls")
       "$TEXMACS_HOME_PATH/plugins/mma/wolfram/tmWolfram.wls"
       "$TEXMACS_PATH/plugins/mma/wolfram/tmWolfram.wls")))

(define (mma-launcher)
  (with boot (raw-quote (mma-entry))
    (with starttm " TEXMACS "
      (with args (if (== (getenv "MMA_DEBUG") "1") " MMA_DEBUG" "")
        (if (url-exists-in-path? "wolframscript")
            (string-append "wolframscript -f " boot starttm args)
            (string-append "wolfram -script " boot starttm args))))))

(plugin-configure mma
  (:winpath "wolframscript" ".")
  (:require (or (url-exists-in-path? "wolframscript")
                (url-exists-in-path? "wolfram")))
  (:serializer ,mma-serialize)
  (:launch ,(mma-launcher))
  (:tab-completion #t)
  (:session "mma")
  (:script "mma"))


(when (supports-mma?)
  (lazy-input-converter (mma-input) mma)
  (import-from (mma-lang))
  (lazy-format (mma-format) mma)
  (lazy-keyboard (mma-edit) in-prog-mma?)
  ;; (plugin-approx-command-set! "mma" "") ; ?
  )

