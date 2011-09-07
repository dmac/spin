#lang racket

(require web-server/servlet
         web-server/servlet-env
         web-server/dispatch
         web-server/http/bindings
         web-server/http/request-structs
         net/url-structs)

(provide get
         params
         run!)

(define current-request null)

(define (params id)
  (hash-ref (make-hash (request-bindings current-request)) id))

(define-syntax-rule (get path body-fn)
  (dispatch-rules! app-container
                   [(path) (render/body body-fn)]))

(define-container app-container (app-dispatch app-url))

(define (render/body body-fn)
  (lambda (req)
    (set! current-request req)
    (response/full 200 #"OK"
                   (current-seconds) TEXT/HTML-MIME-TYPE
                   '()
                   (list (string->bytes/utf-8 (body-fn))))))

(define (run!)
  (serve/servlet app-dispatch
                 #:servlet-regexp #rx""
                 #:command-line? #t))

