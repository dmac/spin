#lang racket

(require "spinneret.rkt")

(get "/"
     (lambda () "Index page"))

(get "/hi" (lambda (req) (string-append "Hi, " (params req 'name))))

(post "/hi"
      (lambda () "You posted!!!"))

(run!)
