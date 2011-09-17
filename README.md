# Spin

Write RESTful web apps in Racket.

Spin layers some convenience functions on top of Racket's built-in web server to simplify defining routes and route handlers.

## Overview

Define routes with one of `get`, `post`, `put`, `patch`, `delete` and pass it the route string and a handler function.

```
#lang racket

(require "spin.rkt")

(get "/"
  (lambda () "Hello!"))

(run)
```

## Params

Your handler function will be passed the request object if an argument is specified.

It can be given to the `params` function along with a key to search for values in the query-string, post-body, or url.

```
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

Retrive params from the url string itself:

```
(get "/hi/:name" (lambda (req)
  (string-append "Hello, " (params req 'name) "!")))
```

```
$ curl "http://localhost:8000/hi/Peter" -X POST
Hello, Peter!
```

## Templating

Your handler function need only return a string to render. You can easily use existing templating libraries with Spin.

**app.rkt**

```
(require web-server/templates)

(get "/template" (lambda (req)
  (define name (params req 'name))
  (include-template "index.html")))

(run)
```

**index.html**

```
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

```
(get "/headers" (lambda ()
  (define h (header #"Custom-Header" #"Itsy bitsy"))
  `(201 (,h) "Look for the custom header!")))
```

## Requirements

Due to a recent [bug fix](https://github.com/plt/racket/commit/78151e073b696522cb187c5cb480bd9cb9d5599c) with how Racket's web server handles certain HTTP requests, Spin requires Racket version 5.1.3.9 or greater.

Nightly versions of Racket can be downloaded [here](http://pre.plt-scheme.org/installers/).

