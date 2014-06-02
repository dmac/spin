#lang racket

(require "main.rkt"
         web-server/servlet
         web-server/templates
         json)

(get "/" (lambda () "GET request"))

(post "/" (lambda () "POST request"))

(put "/" (lambda () "PUT request"))

(delete "/" (lambda () "DELETE request"))

(get "/hi/:name" (lambda (req)
  (string-append "Hi, " (params req 'name))))

(get "/hi/:first_name/:last_name" (lambda (req)
  (define first_name (params req 'first_name))
  (define last_name (params req 'last_name))
  (include-template "index.html")))

(get "/headers" (lambda (req)
  (define h (header #"Custom-Header" #"This is a custom header"))
  `(200 (,h) "Check out the custom header")))

(post "/payload" (lambda (req)
  (string-append "POSTed payload: " (params req 'payload))))


;; Examples using response makers. A global default response maker can be defined by passing it to the run
;; function, and new handler types can be defined with different response makers.

(define (json-404-response-maker status headers body)
  (response status
            (status->message status)
            (current-seconds)
            #"application/json; charset=utf-8"
            headers
            (let ([jsexpr-body (case status
                                 [(404) (string->jsexpr
                                         "{\"error\": 404, \"message\": \"Not Found\"}")]
                                 [else body])])
              (lambda (op) (write-json (force jsexpr-body) op)))))

(define (json-response-maker status headers body)
  (response status
            (status->message status)
            (current-seconds)
            #"application/json; charset=utf-8"
            headers
            (let ([jsexpr-body (string->jsexpr body)])
              (lambda (op) (write-json (force jsexpr-body) op)))))

(define (json-get path handler)
  (define-handler "GET" path handler json-response-maker))

(json-get "/json" (lambda (req)
  "{\"body\":\"JSON GET\"}"))

(run #:response-maker json-404-response-maker)
