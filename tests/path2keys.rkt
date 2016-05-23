#lang racket

;; A simple collection of tests to verify the correct behaviour of the 
;; complementary path->keys and compile-path functions

(require rackunit)
(require (for-syntax "./test-syntax-utils.rkt"))

(define-syntax include-main-locally (ignore-lang-once))
(include "../main.rkt")

;; verify the old behaviour
(check-equal? (path->keys "/aPathBase/id") '())
(check-equal? (path->keys "/aPathBase/:id") '(id))
(check-equal? (path->keys "/aPathBase/:id1/:id2") '(id1 id2))
(check-equal? (path->keys "/aPathBase/:id1/aPathPart/:id2") '(id1 id2))

;; now verify the new behaviour
(check-equal? (path->keys "/aRootPath/*subPath")     '(subPath))
(check-equal? (path->keys "/aRootPath/:id/*subPath") '(id subPath))
(check-equal? (path->keys "/aRootPath/*subPath/:id") '(subPath id))

(check-equal? (path->keys "/aRootPath/:id1/*subPath/:id2")
  '(id1 subPath id2))
(check-equal? (path->keys "/aRootPath/:id1/*subPath1/:id2/*subPath2")
  '(id1 subPath1 id2 subPath2))

;; verify the old behaviour
(check-equal? (compile-path "/aPathBase/id") "^/aPathBase/id(?:$|\\?)" )
(check-equal? (compile-path "/aPathBase/:id") "^/aPathBase/([^/?]+)(?:$|\\?)" )
(check-equal? (compile-path "/aPathBase/:id1/:id2")
   "^/aPathBase/([^/?]+)/([^/?]+)(?:$|\\?)" )
(check-equal? (compile-path "/aPathBase/:id1/aPathPart/:id2")
   "^/aPathBase/([^/?]+)/aPathPart/([^/?]+)(?:$|\\?)" )

;; now verify the new behaviour
(check-equal? (compile-path "/aPathBase/*subPath")
  "^/aPathBase/([^?]+)(?:$|\\?)" )
(check-equal? (compile-path "/aPathBase/:id/*subPath")
  "^/aPathBase/([^/?]+)/([^?]+)(?:$|\\?)" )
(check-equal? (compile-path "/aPathBase/*subPath/:id")
  "^/aPathBase/([^?]+)/([^/?]+)(?:$|\\?)" )
(check-equal? (compile-path "/aPathBase/:id1/*subPath/:id2")
  "^/aPathBase/([^/?]+)/([^?]+)/([^/?]+)(?:$|\\?)" )
(check-equal? (compile-path "/aPathBase/:id1/*subPath1/:id2/*subPath2")
  "^/aPathBase/([^/?]+)/([^?]+)/([^/?]+)/([^?]+)(?:$|\\?)" )


;; We now want to verify old behaviour on the construction of the
;; url-pairs. To keep things as simple as possible, we make small changes
;; to a copy of the relevant code from ../main.rkt and test it locally.
;;
;; Instead of using a request object we simply use the compiled-path and
;; url.
;;
(define (local-request->key-bindings orig-path request-url)
  (define path-regexp (compile-path orig-path))
  (define keys        (path->keys   orig-path))
  (define bindings (cdr (regexp-match path-regexp request-url)))
  (for/list ([key keys] [binding bindings])
            (cons key binding)))


;; verify the old behaviour
(check-equal? (local-request->key-bindings
  "/aPathBase/id" "/aPathBase/id")
  '() )
(check-equal? (local-request->key-bindings
  "/aPathBase/:id" "/aPathBase/anId")
  '((id . "anId")) )
(check-equal? (local-request->key-bindings
  "/aPathBase/:id1/:id2" "/aPathBase/anId1/anId2")
  '((id1 . "anId1") (id2 . "anId2")) )
(check-equal? (local-request->key-bindings
  "/aPathBase/:id1/aPathPart/:id2" "/aPathBase/anId1/aPathPart/anId2")
  '((id1 . "anId1") (id2 . "anId2")) )

;; now verify the new behaviour
(check-equal? (local-request->key-bindings
  "/aPathBase/*subPath" "/aPathBase/aPathPart1/aPathPart2")
  '((subPath . "aPathPart1/aPathPart2")) )
(check-equal? (local-request->key-bindings
  "/aPathBase/:id/*subPath" "/aPathBase/anId/aPathPart1/aPathPart2")
  '((id . "anId") (subPath . "aPathPart1/aPathPart2")) )
(check-equal? (local-request->key-bindings
  "/aPathBase/*subPath/:id" "/aPathBase/aPathPart1/aPathPart2/anId")
  '((subPath . "aPathPart1/aPathPart2") (id . "anId")) )
(check-equal? (local-request->key-bindings
  "/aPathBase/:id1/*subPath/:id2"
  "/aPathBase/anId1/aPathPart1/aPathPart2/anId2")
  '((id1 . "anId1") (subPath . "aPathPart1/aPathPart2") (id2 . "anId2")) )
(check-equal? (local-request->key-bindings
  "/aPathBase/:id1/*subPath1/fixedPart/:id2/*subPath2"
  "/aPathBase/anId1/aPathPart1/aPathPart2/fixedPart/anId2/aPathPart3/aPathPart4")
  '((id1 . "anId1")
    (subPath1 . "aPathPart1/aPathPart2")
    (id2 . "anId2")
    (subPath2 . "aPathPart3/aPathPart4")
  )
)
(check-equal? (local-request->key-bindings
  "/aPathBase/:id1/*subPath1/:id2/fixedPart/*subPath2"
  "/aPathBase/anId1/aPathPart1/aPathPart2/anId2/fixedPart/aPathPart3/aPathPart4")
  '((id1 . "anId1")
    (subPath1 . "aPathPart1/aPathPart2")
    (id2 . "anId2")
    (subPath2 . "aPathPart3/aPathPart4")
  )
)

