#lang racket

; TODO
; * What's the best way to access params? Have it be a hash? Or with "magic" (params 'key) syntax?
; * Integrate with Racket's existing templating frameworks

(require web-server/servlet
         web-server/servlet-env
         web-server/dispatch
         web-server/http/bindings
         web-server/http/request-structs
         net/url-structs)

(provide get post put patch delete
         params
         run!)

(define request-handlers (make-hash))

(define (define-handler method path handler)
  (let ([url-hash (hash-ref request-handlers method (make-hash))])
    (hash-set! url-hash path handler)
    (hash-set! request-handlers method url-hash)))

(define (request->handler request)
  (let ([handler (hash-ref
                   (hash-ref request-handlers (request-method request) #f)
                   (first (regexp-split #rx"\\?" (url->string (request-uri request))))
                   #f)])
    (if handler
      (render/body handler request)
      (render/404))))

; TODO: Make this work with all kinds of params: path, query string, request body
(define (params request id)
  (hash-ref (make-hash (request-bindings request)) id #f))

(define (get path handler) (define-handler #"GET" path handler))
(define (post path handler) (define-handler #"POST" path handler))
(define (put path handler) (define-handler #"PUT" path handler))
(define (patch path handler) (define-handler #"PATCH" path handler))
(define (delete path handler) (define-handler #"DELETE" path handler))

(define (render/body handler request)
  (define content
    (case (procedure-arity handler)
      [(1) (handler request)]
      [else (handler)]))
  (response/full 200 #"OK"
                 (current-seconds) TEXT/HTML-MIME-TYPE
                 '()
                 (list (string->bytes/utf-8 content))))

(define (render/404)
  (response/full 404 #"Not Found"
                 (current-seconds) TEXT/HTML-MIME-TYPE
                 '()
                 '(#"Not Found")))

(define (run!)
  (serve/servlet request->handler
                 #:servlet-regexp #rx""
                 #:command-line? #t))

