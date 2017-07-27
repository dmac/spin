# Spin

Write RESTful web apps in Racket.

Spin layers some convenience functions on top of Racket's built-in web server to simplify defining routes and route handlers.

## Installation
From the command line, run `raco pkg install https://github.com/dmac/spin.git` to install the package.

## Overview

Define routes with one of `get`, `post`, `put`, `patch`, `delete` and pass it the route string and a handler function.

```scheme
#lang racket

(require (planet dmac/spin))

(get "/"
  (lambda () "Hello!"))

(run)
```

## Params

Your handler function will be passed the request object if an argument is specified.

It can be given to the `params` function along with a key to search for values in the query-string, post-body, or url.

```scheme
(get "/hi" (lambda (req)
  (string-append "Hello, " (params req 'name) "!")))
```

```
$ curl "http://localhost:8000/hi?name=Charlotte"
Hello, Charlotte!
```

```
$ curl "http://localhost:8000/hi" -X POST -d "name=Anansi"
Hello, Anansi!
```

Retrieve params from the url string itself:

```scheme
(get "/hi/:name" (lambda (req)
  (string-append "Hello, " (params req 'name) "!")))
```

```
$ curl "http://localhost:8000/hi/Peter"
Hello, Peter!
```

## Templating

Your handler function need only return a string to render. You can easily use existing templating libraries with Spin.

**app.rkt**

```scheme
(require web-server/templates)

(get "/template" (lambda (req)
  (define name (params req 'name))
  (include-template "index.html")))

(run)
```

**index.html**

```html
<html>
  <body>
    <p>Hello, @|name|!</p>
  </body>
</html>
```

```
$ curl "http://localhost:8000/template?name=Aragog"
<html>
  <body>
    <p>Hello, Aragog!</p>
  </body>
</html>
```

## Advanced Responses

In addition to the response body, you can specify response status and custom headers if you return a list instead of a string from your handler:

```scheme
(get "/headers" (lambda ()
  (define h (header #"Custom-Header" #"Itsy bitsy"))
  `(201 (,h) "Look for the custom header!")))
```

## Response Makers

Response makers are middleware that transform a response before it is sent to the client.

A global default response maker can be defined by passing it to the run function:

```scheme
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

(run #:response-maker json-404-response-maker)
```

It is also possible to define new handler types that use different response makers:

```scheme
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
```

## Contributors

- Felipe Oliveira Carvalho ([@philix](https://github.com/philix))
- Jordan Johnson ([@RenaissanceBug](https://github.com/RenaissanceBug))
