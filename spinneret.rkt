#lang racket

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
                   (url->string (request-uri request)) #f)])
    (if handler
      (render/body handler)
      (render/404))))

(define (params request id)
  (hash-ref (make-hash (request-bindings request)) id))

(define (get path handler) (define-handler #"GET" path handler))
(define (post path handler) (define-handler #"POST" path handler))
(define (put path handler) (define-handler #"PUT" path handler))
(define (patch path handler) (define-handler #"PATCH" path handler))
(define (delete path handler) (define-handler #"DELETE" path handler))

(define (render/body body-fn)
  (response/full 200 #"OK"
                 (current-seconds) TEXT/HTML-MIME-TYPE
                 '()
                 (list (string->bytes/utf-8 (body-fn)))))

(define (render/404)
  (response/full 404 #"Not Found"
                 (current-seconds) TEXT/HTML-MIME-TYPE
                 '()
                 '(#"Not Found")))

(define (run!)
  (serve/servlet request->handler
                 #:servlet-regexp #rx""
                 #:command-line? #t))

