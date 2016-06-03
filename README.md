# Spin

Write RESTful web apps in Racket.

Spin layers some convenience functions on top of Racket's built-in web server to simplify defining routes and route handlers.

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

Retrieve params from the url string itself using a single ('/'-delimited)
field:

```scheme
(get "/hi/:name" (lambda (req)
  (string-append "Hello, " (params req 'name) "!")))
```

```
$ curl "http://localhost:8000/hi/Peter"
Hello, Peter!
```

or using a multi-field "wildcard":


```scheme
(get "/appFiles/*file-path" (lambda (req)
  (string-append "Requested file: " (params req 'file-path) "!")))
```

```
$ curl "http://localhost:8000/appFiles/images/image.png"
Requested file: images/image.png
```

or any mixture of either single ('/'-delimited) fields or multi-field
wildcards.

**Note** that multiple multi-field wildcards will only work *if* there is
a fixed field between the wildcard fields:

```scheme
(get "/title/*title/date/*date" (lambda (req)
  (string-append
    "Post title: " (params req 'title)
    "\nPost  date: " (params req 'date)
  )))
```

```
$ curl "http://localhost:8000/title/proving/computations/correct/date/2016/05/23/"
Post title: proving/computations/correct
Post  date: 2016/05/23
```

(anything will work so long as it does not start with either ':' or '*').

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

## Serving binary files

There are two ways to serve binary files.

### Small binary files using spin routing

<pre>
(require "./binaryServlets.rkt")
</pre>

Small binary files can be served using the "get-file" function:

<pre>
(get-file "/zepto" "browser/vendor" 3600)
</pre>

when requested using the "GET" method, with a URL which begins with 
"/zepto", this route will serve the corresponding binary files in the 
"browser/vendor" filesystem directory located relative to the 
current-directory. These files will have a expiry time of one hour (60x60 
= 3600 seconds) from the time it was sent to the client.

**Notes:**

1. This get-file function does *not* make use of http range requests, 
hence *only* relatively "small" files can be served reliably.

2. At the moment *only* the "GET" method is defined.

### Larger binary files using Racket Web-application.

You can use the standard [Racket 
web-application](https://docs.racket-lang.org/web-server/) tools with the 
spin based routes **IF** you provide something like the following custom 
response-maker:

<pre>
(define (next-dispatcher-response-maker status headers body)
  (next-dispatcher)
)
</pre>

which ignores any status headers or body and uses the [standard Racket 
web-application 
way](https://docs.racket-lang.org/web-server-internal/dispatch.html?q=next-#%28def._%28%28lib._web-server%2Fdispatchers%2Fdispatch..rkt%29._next-dispatcher%29%29) 
of signalling that this dispatcher has not found any valid response.

Then in the spin run function you would use:

<pre>
(run 
  #:response-maker next-dispatcher-response-maker
  #:extra-files-paths [
    ... a list of filesystem file paths ...
  ]
)
</pre>

to ensure that the next-dispatcher-response-maker is used whenever the 
spin based routes do not find any valid response. Refer to the 
[serve/servlet](https://docs.racket-lang.org/web-server/run.html#%28def._%28%28lib._web-server%2Fservlet-env..rkt%29._serve%2Fservlet%29%29) 
documentation for the use of the "#:extra-files-paths" key word.

**Notes:**

1. The standard Racket web-application *does* make full use of the HTTP 
range requests to serve very large files. 

2. Unfortunately the standard Racket web-application does not specify any 
expiry times nor does it recognize the Cache-Control, or 
If-Modified-Since headers.

## Contributors

- Felipe Oliveira Carvalho ([@philix](https://github.com/philix))
- Jordan Johnson ([@RenaissanceBug](https://github.com/RenaissanceBug))
