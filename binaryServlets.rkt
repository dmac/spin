#lang racket

(require racket/date)
(require net/url)
(require 
  web-server/http/request-structs
  web-server/http/response-structs
)
(require "./main.rkt")

(provide 
  get-file
  binary-response-maker
)

(define (path->mime-type file-path)
  (case (string-downcase (bytes->string/utf-8 (filename-extension file-path)))
    [ ("js")  #"application/javascript" ]
    [ ("png") #"image/png" ]
    [ ("css") #"text/css" ]
    [ else #"unknown" ]
  )
)

(date-display-format 'rfc2822)

(define (binary-response-maker status headers body)
  (response/full
    status
    (status->message status)
    (current-seconds)
    (header-value (car headers))
    (cdr headers)
    (list body)
  )
)

(define (get-file path file-path expires-in-seconds)
  ;;(displayln (string-append "get-file [" path "] [" (path->string file-path) "] [" (number->string expires-in-seconds) "]"))
  (define (binary-file-handler req)
    (define filePath (build-path file-path (params req 'filePath)))
    ;;(displayln (string-append "REQUESTING [" (url->string (request-uri req)) "]"))
    ;;(displayln (string-append "  as file  [" (path->string filePath) "]"))
    ;;(displayln (path->mime-type filePath))
    (if (file-exists? filePath)
      (let* (
        [ file-port (open-input-file filePath #:mode 'binary) ]
        [ contents (port->bytes file-port) ] )
        (begin
          (close-input-port file-port)
          (list 
            200
            (list
              (header #"Content-Type"
                (path->mime-type filePath))
              (header #"Content-Length"
                (string->bytes/utf-8 
                  (number->string (file-size filePath))))
              (header #"Expires"
                (string->bytes/utf-8 
                  (date->string 
                    (seconds->date 
                      (+ (current-seconds) expires-in-seconds)))))
              (header #"Last-Modified"
                (string->bytes/utf-8
                  (date->string 
                    (seconds->date
                      (file-or-directory-modify-seconds filePath)))))
            )
            contents
          )
        )
      )
      `(404
        ( ,(header #"" #"")
          ,(header #"" #"")
        )
        ,(string->bytes/utf-8 
          (string-append 
            "The url ["
            (url->string (request-uri req))
            "] could not be found on this server."
          )
        )
      )
    )
  )
  (define-handler
    "GET"
    (string-append path "/*filePath")
    binary-file-handler
    binary-response-maker
  )
)

