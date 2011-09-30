#lang racket

(require (planet dmac/spin)
         web-server/templates)

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

(run)
