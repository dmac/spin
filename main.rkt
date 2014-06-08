#lang racket

; TODO
; * tests
; * look into ORMs

(require web-server/servlet
         web-server/servlet-env
         web-server/http/bindings
         web-server/http/request-structs
         net/url-structs)

(provide get post put patch delete
         default-response-maker
         status->message
         define-handler
         params
         header
         run)

(define (get path handler) (define-handler "GET" path handler))
(define (post path handler) (define-handler "POST" path handler))
(define (put path handler) (define-handler "PUT" path handler))
(define (patch path handler) (define-handler "PATCH" path handler))
(define (delete path handler) (define-handler "DELETE" path handler))

(define (default-response-maker status headers body)
  (response/full status
                 (status->message status)
                 (current-seconds)
                 TEXT/HTML-MIME-TYPE
                 headers
                 (list (string->bytes/utf-8 body))))

(define run
  (make-keyword-procedure
    (lambda (kws kw-args . etc)
      (cond
        [(not (empty? etc))
         (error 'run
                "expected kw args (for serve/servlet) only; found ~a non-kw args"
                (length etc))]
        [(ormap (curryr memq '(#:servlet-regexp #:command-line?)) kws)
         (error 'run
                "kw args may not include #:servlet-regexp or #:command-line?")]
        [else
         (let* ([kw-pairs (append '((#:servlet-regexp #rx"")
                                    (#:command-line? #t))
                                  (filter (lambda (kw-pair)
                                            (not (eq? '#:response-maker (car kw-pair))))
                                          (map list kws kw-args)))]
                [sorted-pairs (sort kw-pairs keyword<? #:key first)]
                [response-maker (let ([response-maker-pair
                                       (findf (lambda (p) (eq? (car p) '#:response-maker))
                                              (map list kws kw-args))])
                                  (if response-maker-pair
                                      (cadr response-maker-pair)
                                      default-response-maker))])
           (keyword-apply serve/servlet
                          (map first sorted-pairs)
                          (map second sorted-pairs)
                          (list (lambda (req)
                                  (request->handler req response-maker)))))]))))

(define (params request key)
  (define query-pairs (url-query (request-uri request)))
  (define body-pairs
    (match (request-post-data/raw request)
      [#f empty]
      [body (url-query (string->url (string-append "?" (bytes->string/utf-8 body))))]))
  (define url-pairs
    (let ([keys (cadr (request->handler/keys/response-maker request))])
      (request->key-bindings request keys)))
  (hash-ref (make-hash (append query-pairs body-pairs url-pairs)) key ""))

(define request-handlers (make-hash))

(define (define-handler method path handler [response-maker default-response-maker])
  (define keys (path->keys path))
  (define path-regexp (compile-path path))
  (define handler/keys/response-maker (list handler keys response-maker))
  (hash-set! request-handlers
             (string-append method " " path-regexp)
             handler/keys/response-maker))

(define (path->keys path)
  (map (lambda (match) (string->symbol (substring match 2)))
       (regexp-match* #rx"/:([^\\/]+)" path)))

(define (compile-path path)
  (string-append
    "^"
    (regexp-replace* #rx":[^\\/]+" path "([^/?]+)")
    "(?:$|\\?)"))

(define (request->handler request
                          response-maker)
  (define handler/keys/response-maker (request->handler/keys/response-maker request))
  (begin
    (cond
      [handler/keys/response-maker (render/handler (car handler/keys/response-maker)
                                                   request
                                                   (caddr handler/keys/response-maker))]
      [else (render/404 response-maker)])))

(define (request->handler/keys/response-maker request)
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

(define (render/handler handler request response-maker)
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

  (response-maker status headers body))

(define (render/404 response-maker)
  (response-maker 404
                  '()
                  "Not Found"))

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
