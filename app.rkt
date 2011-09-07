#lang racket

(require "spinneret.rkt")

(get ""
     (lambda () "This is the index"))

(get "hello"
     (lambda ()
       (string-append "Hello, " (params 'name) "!")))

(run!)
