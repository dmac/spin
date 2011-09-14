#lang racket

(require "spinneret.rkt")

(get "/"
     (lambda () "Index page"))

(get "/hi" (lambda (req) (string-append "Hi, " (params req 'name))))

(post "/"
      (lambda (req) (string-append "You posted, " (params req 'name))))

(put "/"
      (lambda (req) (string-append "You posted, " (params req 'name))))

(run!)
