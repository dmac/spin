#lang racket

(require "spin.rkt"
         web-server/templates)

(get "/" (lambda () "Index"))

(get "/hi/:name" (lambda (req)
  (string-append "Hi, " (params req 'name))))

(get "/hi/:first_name/and/:second_name" (lambda (req)
  (define first_name (params req 'first_name))
  (define second_name (params req 'second_name))
  (include-template "index.html")))

(run!)
