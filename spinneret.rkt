#lang racket

(require web-server/servlet
         web-server/servlet-env
         web-server/dispatch)

(provide get
         run)

(define-syntax-rule (get path request-body)
  (dispatch-rules! app-container
                   [(path) (render/text request-body)]))

(define-container app-container (app-dispatch app-url))

; The render/xxx methods take some contents and return
; a function that accepts a request, suitable to be
; passed to dispatch-rules.
; Examples: render/text, render/template
(define (render/text text)
  (lambda (req)
    (response/xexpr `(p ,text))))

(define (run)
  (serve/servlet app-dispatch
                 #:servlet-regexp #rx""
                 #:command-line? #t))

