#lang racket

(require "spin.rkt"
         web-server/templates)

(get "/" (lambda ()
           (define name "Daniel")
           (include-template "index.html")))

(get "/hi" (lambda (req)
             (define name (params req 'name))
             (include-template "index.html")))

(post "/"
      (lambda (req) (string-append "You posted, " (params req 'name))))

(put "/"
      (lambda (req) (string-append "You posted, " (params req 'name))))

(run!)
