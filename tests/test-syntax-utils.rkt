#lang racket

;; This is collection of utility functions for use while testing

(provide ignore-lang-once)

;; ignore-lang-once temporarily changes the current-readtable so that it 
;; **ignores** the next #lang statement...
;;  ... this allows the internals of the next included file to be locally 
;; defined... and hence testable.
;;
;; EXAMPLE:
;; --------------------------------------------------------------------
;;
;;   (require (for-syntax "./test-syntax-utils.rkt"))
;;
;;   ....
;;
;;   (define-syntax include-main-locally (ignore-lang-once))
;;   (include "../main.rkt")
;;
;; --------------------------------------------------------------------
;;
(define (ignore-lang-once)
  (let ( [ old-readtable (current-readtable) ] )
    (current-readtable
      (make-readtable
        old-readtable
        #\l
        'dispatch-macro
        (lambda (trigger-char port . ignored-args)
          (current-readtable old-readtable)
          (make-special-comment (read-line port 'any))
        )
      )
    )
  )
)

