
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : mma-indent.scm
;; DESCRIPTION : Editing Wolfram programs
;; COPYRIGHT   : (C) 2022 Hammer Hu
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(texmacs-module (mma-edit)
  (:use (wolfram-indent)))

;; (tm-define (kbd-variant t forward?)
;;   (:require (and (in-prog-mma?) (not (inside? 'session)))))

;; Enable highlighting matching brackets
(tm-define (notify-cursor-moved status)
  (:require prog-highlight-brackets?)
  (:mode in-prog-mma?)
  (select-brackets-after-movement "([{" ")]}" "\\"))

(tm-define (insert-return)
  (:mode in-prog-mma?)
  (insert-raw-return)
  (wolfram-indent))
