#lang racket

(require "spin.rkt"
         web-server/templates)

(get "/" (lambda () "Index"))

(get "/hi/:name" (lambda (req)
  (string-append "Hi, " (params req 'name))))

(get "/headers" (lambda (req)
  (define h (header #"X_HTTP_CUSTOM" #"Custom header!"))
  (list 200 (list h) "Check out the custom header")))

(get "/hi/:first_name/and/:second_name" (lambda (req)
  (define first_name (params req 'first_name))
  (define second_name (params req 'second_name))
  (include-template "index.html")))

(run)
