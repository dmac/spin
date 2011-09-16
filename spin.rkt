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

(define (get path handler) (define-handler "GET" path handler))
(define (post path handler) (define-handler "POST" path handler))
(define (put path handler) (define-handler "PUT" path handler))
(define (patch path handler) (define-handler "PATCH" path handler))
(define (delete path handler) (define-handler "DELETE" path handler))

(define (run!)
  (serve/servlet request->handler
                 #:servlet-regexp #rx""
                 #:command-line? #t))

(define (params request key)
  (define query-pairs (url-query (request-uri request)))
  (define body-pairs
    (match (request-post-data/raw request)
      [#f empty]
      [body (url-query (string->url (string-append "?" (bytes->string/utf-8 body))))]))
  (define url-pairs
    (let ([keys (cdr (request->handler/keys request))])
      (request->key-bindings request keys)))
  (hash-ref (make-hash (append query-pairs body-pairs url-pairs)) key ""))

(define request-handlers (make-hash))

(define (define-handler method path handler)
  (define keys (path->keys path))
  (define path-regexp (compile-path path))
  (define handler/keys (cons handler keys))
  (hash-set! request-handlers
             (string-append method " " path-regexp)
             handler/keys))

(define (path->keys path)
  (map (lambda (match) (string->symbol (substring match 2)))
       (regexp-match* #rx"/:([^\\/]+)" path)))

(define (compile-path path)
  (string-append
    "^"
    (regexp-replace* #rx":[^\\/]+" path "([^/?]+)")
    "(?:$|\\?)"))

(define (request->handler request)
  (define handler/keys (request->handler/keys request))
  (cond
    (handler/keys (render/body (car handler/keys) request))
    (else (render/404))))

(define (request->handler/keys request)
  (define handler-key (request->matching-key request))
  (case handler-key
    [(#f) #f]
    [else (hash-ref request-handlers handler-key #f)]))

(define (request->key-bindings request keys)
  (define path-regexp
    (second (regexp-split #rx" " (request->matching-key request))))
  (define bindings (cdr (regexp-match path-regexp (url->string (request-uri request)))))
  (for/list ([key keys] [binding bindings])
            (cons key binding)))

(define (request->matching-key request)
  (define (key-matches-route? key)
    (match-define (list _ method path-regexp)
                  (regexp-match #rx"([^ ]+) ([^ ]+)" key))
    (and (equal? (request-method request) (string->bytes/utf-8 method))
         (regexp-match (regexp path-regexp)
                       (url->string (request-uri request)))))
  (findf key-matches-route? (hash-keys request-handlers)))


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

