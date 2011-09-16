#lang racket

(require "spin.rkt"
         web-server/templates)

(get "/" (lambda () "Index"))

(get "/hi/:name" (lambda (req)
                   (string-append "Hi, " (params req 'name))))

(get "/hi/:me/hi/:you" (lambda (req)
             (define name (params req 'name))
             (include-template "index.html")))

;(post "/"
;      (lambda (req) (string-append "You posted, " (params req 'name))))

;(put "/"
;      (lambda (req) (string-append "You posted, " (params req 'name))))

(run!)
