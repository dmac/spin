#lang racket

(require "spinneret.rkt")

(get "/"
     (lambda () "Index page"))

(get "/hi"
     (lambda () "Hi there"))

(post "/hi"
      (lambda () "You posted!!!"))

(run!)
