#lang racket

(require rackunit)
(require web-server/http/request-structs)
(require net/url-string)

(require/expose "../main.rkt" 
  (compile-path
   path->keys
  request->handler/keys/response-maker
  request->key-bindings
  request->matching-key
  request-handlers
  get))

;; Unit test path->keys
;;
(check-equal? (path->keys "/base/id") '())
(check-equal? (path->keys "/base/:id") '(id))
(check-equal? (path->keys "/base/:id1/:id2") '(id1 id2))
(check-equal? (path->keys "/base/:id1/path/:id2") '(id1 id2))
(check-equal? (path->keys "/rootPath/*subPath")     '(subPath))
(check-equal? (path->keys "/rootPath/:id/*subPath") '(id subPath))
(check-equal? (path->keys "/rootPath/*subPath/:id") '(subPath id))
(check-equal? (path->keys "/rootPath/:id1/*subPath/:id2")
  '(id1 subPath id2))
(check-equal? (path->keys "/rootPath/:id1/*subPath1/:id2/*subPath2")
  '(id1 subPath1 id2 subPath2))

;; Unit test compile-path
;;
(check-equal? (compile-path "/base/id") "^/base/id(?:$|\\?)")
(check-equal? (compile-path "/base/:id") "^/base/([^/?]+)(?:$|\\?)")
(check-equal? (compile-path "/base/:id1/:id2")
   "^/base/([^/?]+)/([^/?]+)(?:$|\\?)")
(check-equal? (compile-path "/base/:id1/path/:id2")
   "^/base/([^/?]+)/path/([^/?]+)(?:$|\\?)")
(check-equal? (compile-path "/base/*subPath")
  "^/base/([^?]+)(?:$|\\?)")
(check-equal? (compile-path "/base/:id/*subPath")
  "^/base/([^/?]+)/([^?]+)(?:$|\\?)")
(check-equal? (compile-path "/base/*subPath/:id")
  "^/base/([^?]+)/([^/?]+)(?:$|\\?)")
(check-equal? (compile-path "/base/:id1/*subPath/:id2")
  "^/base/([^/?]+)/([^?]+)/([^/?]+)(?:$|\\?)")
(check-equal? (compile-path "/base/:id1/*subPath1/:id2/*subPath2")
  "^/base/([^/?]+)/([^?]+)/([^/?]+)/([^?]+)(?:$|\\?)")

;; Integrated tests of the request->key-bindings function
;;
;; We need to define a number of "helper" functions to both mock a 
;; request as well as make it easy to get the data values required by the 
;; request->key-bindings function itself.
;;
(define (urlStr->fake-request urlStr)
  (make-request
    #"GET"
    (string->url urlStr)
    (list (header #"Accept-Charset" #"utf-8"))
    (delay (lambda () (binding #"unknownId")))
    #f
    "127.0.0.1"
    8080
    "127.0.0.1"))
;;
(define (request->keys request)
  (cadr (request->handler/keys/response-maker request)))
;;
(define (urlStr->key-bindings urlStr)
  (let* ([ request (urlStr->fake-request urlStr) ]
         [ keys (request->keys request) ])
    (request->key-bindings request keys)))
;;
(define (helloWorld)
  "hello world")

;; Now the tests
;;
(get "/example00/id" helloWorld)
(check-equal? (urlStr->key-bindings "/example00/id") '())

(get "/example01/:id" helloWorld)
(check-equal? (urlStr->key-bindings "/example01/id") '((id . "id")))

(get "/example02/:id1/:id2" helloWorld)
(check-equal? (urlStr->key-bindings "/example02/id1/id2")
  '((id1 . "id1") (id2 . "id2")))

(get "/example03/:id1/path/:id2" helloWorld)
(check-equal? (urlStr->key-bindings "/example03/id1/path/id2")
  '((id1 . "id1") (id2 . "id2")))

(get "/example04/*subPath" helloWorld)
(check-equal? (urlStr->key-bindings "/example04/path1/path2")
  '((subPath . "path1/path2")))

(get "/example05/:id/*subPath" helloWorld)
(check-equal? (urlStr->key-bindings "/example05/id/path1/path2")
  '((id . "id") (subPath . "path1/path2")))

(get "/example06/*subPath/:id" helloWorld)
(check-equal? (urlStr->key-bindings "/example06/path1/path2/id")
  '((subPath . "path1/path2") (id . "id")))

(get "/example07/:id1/*subPath/:id2" helloWorld)
(check-equal? (urlStr->key-bindings "/example07/id1/path1/path2/id2")
  '((id1 . "id1") (subPath . "path1/path2") (id2 . "id2")))

(get "/example08/:id1/*subPath1/fixedPart/:id2/*subPath2" helloWorld)
(check-equal? (urlStr->key-bindings 
  "/example08/id1/path1/path2/fixedPart/id2/path3/path4")
  '((id1 . "id1")
    (subPath1 . "path1/path2")
    (id2 . "id2")
    (subPath2 . "path3/path4")))

(get "/example09/:id1/*subPath1/:id2/fixedPart/*subPath2" helloWorld)
(check-equal? (urlStr->key-bindings
  "/example09/id1/path1/path2/id2/fixedPart/path3/path4")
  '((id1 . "id1")
    (subPath1 . "path1/path2")
    (id2 . "id2")
    (subPath2 . "path3/path4")))
