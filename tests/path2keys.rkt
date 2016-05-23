#lang racket

;; A simple collection of tests to verify the correct behaviour of the 
;; path->keys function

(require rackunit)
(require (for-syntax "./test-syntax-utils.rkt"))

(define-syntax include-main-locally (ignore-lang-once))
(include "../main.rkt")

(check-equal? (path->keys "/aPathBase/id") '())
(check-equal? (path->keys "/aPathBase/:id") '(id))
(check-equal? (path->keys "/aPathBase/:id1/:id2") '(id1 id2))
(check-equal? (path->keys "/aPathBase/:id1/aPathPart/:id2") '(id1 id2))
;;(check-eq? (path->keys "/aRootPath/*test") '(test))


(check-equal? (compile-path "/aPathBase/id") "^/aPathBase/id(?:$|\\?)" )
(check-equal? (compile-path "/aPathBase/:id") "^/aPathBase/([^/?]+)(?:$|\\?)" )
(check-equal? (compile-path "/aPathBase/:id1/:id2")
   "^/aPathBase/([^/?]+)/([^/?]+)(?:$|\\?)" )
(check-equal? (compile-path "/aPathBase/:id1/aPathPart/:id2")
   "^/aPathBase/([^/?]+)/aPathPart/([^/?]+)(?:$|\\?)" )
;;(check-equal? (compile-path "/aRootPath/*test") "^/aRootPath/([^/?]+)(?:$|\\?)" )
