#lang setup/infotab
(define name "spin")
(define blurb
  (list '(p "Write RESTful web apps in Racket.")))
(define release-notes
  (list '(ul (li "Support for serve/servlet args")
             (li "Customizable response handlers"))))
(define primary-file "main.rkt")
(define categories '(net))
(define homepage "https://github.com/dmacdougall/spin")
(define version "1.3")
(define required-core-version "5.2")
(define repositories
  (list "4.x"))
