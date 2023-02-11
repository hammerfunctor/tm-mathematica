
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
 (mw-converter)
 )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mma source files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(texmacs-modes
 (in-mma% (== (get-env "prog-language") "mma"))
 (in-prog-mma% #t in-prog% in-mma%))


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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Plugin Configuration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; (use-modules (mma-math-converter))
;; (define (mma-pre-serialize lan t)
;;   (cond ((func? t 'document 1)
;;          (mma-pre-serialize lan (mma-map-math lan '() (cadr t))))
;; 	((func? t 'math 1)
;;          (mma-pre-serialize lan (mma-map-math lan '() t)))
;; 	(else t)))

(define (mma-pre-serialize-rec lan serialized this rest)
  ;;(display "Here comes: ")
  ;;(display this)
  ;;(display "\n")
  (let* ((this-serialized
          (cond ((func? this 'math) (mma-map-math lan '() this))
                ((func? this 'document)
                 (mma-pre-serialize-rec lan '(document) (cadr this) (cddr this)))
                (else this)))
         (serialized-new (append serialized (list this-serialized))))
    (if (null? rest)
        serialized-new
        (mma-pre-serialize-rec lan serialized-new (car rest) (cdr rest)))))

(define (mma-pre-serialize lan t)
  (cond ((func? t 'math 1)
         ;;(display "mma-pre-serialize: 1\n")
         (mma-map-math lan '() t))
        ((func? t 'document 1)
         ;;(display "mma-pre-serialize: 2\n")
         (mma-pre-serialize lan (cadr t)))
        ((func? t 'document)
         ;;(display "mma-pre-serialize: 3\n")
         (mma-pre-serialize-rec lan '(document) (cadr t) (cddr t)))
        (else
         ;;(display "mma-pre-serialize: 4\n")
         ;;(display "This is not captured: ")
         ;;(display t)
         t)))



(define (mma-serialize lan t)
  (with u (mma-pre-serialize lan t)
    ;;(display u)
    (with s (texmacs->code (stree->tree u) "SourceCode")
      (string-append s "\nEndOfFile\n"))))

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

(when (supports-mma?)
  ;;(import-from (mma-menus))
  (import-from (mma-lang))
  (lazy-input-converter (mma-input) mma)
  (lazy-keyboard (mma-edit) in-prog-mma?)
  ;; (plugin-approx-command-set! "mma" "") ; ?
  )

