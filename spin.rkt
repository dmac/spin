#lang racket

; TODO
; * allow headers to be specified as strings rather than (header?)
; * tests??
; * look into ORMs

(require web-server/servlet
         web-server/servlet-env
         web-server/http/bindings
         web-server/http/request-structs
         net/url-structs)

(provide get post put patch delete
         params
         run)

(define (get path handler) (define-handler "GET" path handler))
(define (post path handler) (define-handler "POST" path handler))
(define (put path handler) (define-handler "PUT" path handler))
(define (patch path handler) (define-handler "PATCH" path handler))
(define (delete path handler) (define-handler "DELETE" path handler))

(define (run #:port [port 8000])
  (serve/servlet request->handler
                 #:port port
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
    (handler/keys (render/handler (car handler/keys) request))
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

(define (render/handler handler request)
  (define content
    (case (procedure-arity handler)
      [(1) (handler request)]
      [else (handler)]))
  (define status
    (cond [(list? content) (first content)]
          [else 200]))
  (define headers
    (cond [(list? content) (second content)]
          [else '()]))
  (define body
    (cond [(list? content) (third content)]
          [else content]))

  (response/full status
                 (status->message status)
                 (current-seconds)
                 TEXT/HTML-MIME-TYPE
                 headers
                 (list (string->bytes/utf-8 body))))

(define (render/404)
  (response/full 404
                 (status->message 404)
                 (current-seconds)
                 TEXT/HTML-MIME-TYPE
                 '()
                 '(#"Not Found")))

(define (status->message status)
  (case status
    [(100) #"Continue"]
    [(101) #"Switching Protocols"]
    [(200) #"OK"]
    [(201) #"Created"]
    [(202) #"Accepted"]
    [(203) #"Non-Authoritative Information"]
    [(204) #"No Content"]
    [(205) #"Reset Content"]
    [(206) #"Partial Content"]
    [(300) #"Multiple Choices"]
    [(301) #"Moved Permanently"]
    [(302) #"Found"]
    [(303) #"See Other"]
    [(304) #"Not Modified"]
    [(305) #"Use Proxy"]
    [(307) #"Temporary Redirect"]
    [(400) #"Bad Request"]
    [(401) #"Unauthorized"]
    [(402) #"Payment Required"]
    [(403) #"Forbidden"]
    [(404) #"Not Found"]
    [(405) #"Method Not Allowed"]
    [(406) #"Not Acceptable"]
    [(407) #"Proxy Authentication Required"]
    [(408) #"Request Timeout"]
    [(409) #"Conflict"]
    [(410) #"Gone"]
    [(411) #"Length Required"]
    [(412) #"Precondition Failed"]
    [(413) #"Request Entity Too Large"]
    [(414) #"Request-URI Too Long"]
    [(415) #"Unsupported Media Type"]
    [(416) #"Requested Range Not Satisfiable"]
    [(417) #"Expectation Failed"]
    [(500) #"Internal Server Error"]
    [(501) #"Not Implemented"]
    [(502) #"Bad Gateway"]
    [(503) #"Service Unavailable"]
    [(504) #"Gateway Timeout"]
    [(505) #"HTTP Version Not Supported"]
    [else #""]))
