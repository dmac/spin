#lang racket

; TODO
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

(define (get path handler) (define-handler #"GET" path handler))
(define (post path handler) (define-handler #"POST" path handler))
(define (put path handler) (define-handler #"PUT" path handler))
(define (patch path handler) (define-handler #"PATCH" path handler))
(define (delete path handler) (define-handler #"DELETE" path handler))

(define (run!)
  (serve/servlet request->handler
                 #:servlet-regexp #rx""
                 #:command-line? #t))

; TODO: Make this work with path variables
; TODO: The body-pairs logic can probably be cleaned up quite a bit.
(define (params request key)
  (define query-pairs (url-query (request-uri request)))
  (define body-pairs
    (let ([body-raw (request-post-data/raw request)])
      (if body-raw
        (url-query (string->url (string-append "?" (bytes->string/utf-8 body-raw))))
        '())))
  (hash-ref (make-hash (append query-pairs body-pairs)) key ""))

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

