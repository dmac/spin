#lang racket

; TODO
; * Set status from handlers
; * Set content type from handlers
; * tests??

(require web-server/servlet
         web-server/servlet-env
         web-server/http/bindings
         web-server/http/request-structs
         net/url-structs)

(provide get post put patch delete
         params
         run!)

(struct handler/keys (handler keys))

(define (get path handler) (define-handler "GET" path handler))
(define (post path handler) (define-handler "POST" path handler))
(define (put path handler) (define-handler "PUT" path handler))
(define (patch path handler) (define-handler "PATCH" path handler))
(define (delete path handler) (define-handler "DELETE" path handler))

(define (run!)
  (serve/servlet request->handler
                 #:servlet-regexp #rx""
                 #:command-line? #t))

; TODO: Make this work with path variables by using regexps instead of string paths
(define (params request key)
  (define query-pairs (url-query (request-uri request)))
  (define body-pairs
    (match (request-post-data/raw request)
      [#f empty]
      [body (url-query (string->url (string-append "?" (bytes->string/utf-8 body))))]))
  (hash-ref (make-hash (append query-pairs body-pairs)) key ""))

(define request-handlers (make-hash))

; TODO:
; * create handler/keys: (handler . (key ...))
; * use "METHOD path-regexp" => handler/keys
(define (define-handler method path handler)
  (define keys (path->keys path))
  (define path-regexp (compile-path path))
  (displayln path-regexp)
  (hash-set! request-handlers
             (string-append method " " path)
             handler))

(define (path->keys path)
  (map (lambda (match) (string->symbol (substring match 2)))
       (regexp-match* #rx"/:([^\\/]+)" path)))

(define (compile-path path)
  (regexp-replace* #rx":[^\\/]+" path "([^/]+)"))

; TODO:
; * loop through request-handlers keys
; * split on space, check regexp match and method match
; * handler is value from first matching key
(define (request->handler request)
  (define handler-key
    (string-join (list (bytes->string/utf-8 (request-method request))
                       (first (regexp-split #rx"\\?" (url->string (request-uri request)))))
                 " "))
  (define handler (hash-ref request-handlers handler-key #f))
  (cond
    (handler (render/body handler request))
    (else (render/404))))

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

