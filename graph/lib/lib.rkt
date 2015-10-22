#lang typed/racket

(require "low.rkt")
(provide (all-from-out "low.rkt"))

;; Types
(provide AnyImmutable)
;; Functions
(provide ∘ eval-get-values generate-indices)
;; Macros
(provide mapp comment)

(require "eval-get-values.rkt")

(define ∘ compose)

(require (for-syntax syntax/parse
                     racket/syntax))

;; raco pkg install alexis-util
(require alexis/util/threading)

;; From alexis/util/threading
(provide ~> ~>> _ (rename-out [_ ♦]))

(define-syntax (comment stx)
  #'(values))

(define-type AnyImmutable (U Number
                             Boolean
                             True
                             False
                             String
                             Keyword
                             Symbol
                             Char
                             Void
                             ;Input-Port   ;; Not quite mutable, but not really immutable either.
                             ;Output-Port  ;; Not quite mutable, but not really immutable either.
                             ;Port         ;; Not quite mutable, but not really immutable either.
                             #| I haven't checked the mutability of the ones in the #||# comments below
                             Path
                             Path-For-Some-System
                             Regexp 
                             PRegexp
                             Byte-Regexp
                             Byte-PRegexp
                             Bytes
                             Namespace
                             Namespace-Anchor
                             Variable-Reference
                             |#
                             Null
                             #|
                             EOF
                             Continuation-Mark-Set
                             |#
                             ; Undefined ;; We definitely don't want that one, it's not mutable but it's an error if present anywhere 99.9% of the time.
                             #|
                             Module-Path
                             Module-Path-Index
                             Resolved-Module-Path
                             Compiled-Module-Expression
                             Compiled-Expression
                             Internal-Definition-Context
                             Pretty-Print-Style-Table
                             Special-Comment
                             Struct-Type-Property
                             Impersonator-Property
                             Read-Table
                             Bytes-Converter
                             Parameterization
                             Custodian
                             Inspector
                             Security-Guard
                             UDP-Socket ;; Probably not
                             TCP-Listener ;; Probably not
                             Logger ;; Probably not
                             Log-Receiver ;; Probably not
                             Log-Level
                             Thread
                             Thread-Group
                             Subprocess
                             Place
                             Place-Channel
                             Semaphore ;; Probably not
                             FSemaphore ;; Probably not
                             Will-Executor
                             Pseudo-Random-Generator
                             Path-String
                             |#
                             (Pairof AnyImmutable AnyImmutable)
                             (Listof AnyImmutable)
                             ; Plus many others, not added yet.
                             ; -> ; Not closures, because they can contain mutable variables, and we can't eq? them
                             ; maybe Prefab? Or are they mutable?
                             ))

(define-syntax (mapp stx)
  (syntax-parse stx
    [(_ var:id lst:expr body ...)
     #'(let ((l lst))
         (if (null? l)
             '()
             (let ((result (list (let ((var (car l)))
                                   body ...))))
               (set! l (cdr l))
               (do ([stop : Boolean #f])
                 (stop (reverse result))
                 (if (null? l)
                     (set! stop #t)
                     (begin
                       (set! result
                             (cons (let ((var (car l)))
                                     body ...)
                                   result))
                       (set! l (cdr l))))))))]))

;; TODO: this does not work, because Null is (Listof Any)
; (mapp x (cdr '(1)) (* x x))

;; TODO: foldll
(define-syntax (foldll stx)
  (syntax-parse stx
    [(_ var:id acc:id lst:expr init:expr body ...)
     #'(let ((l lst))
         (if (null? l)
             '()
             (let ((result (list (let ((var (car l)))
                                   body ...))))
               (set! l (cdr l))
               (do ([stop : Boolean #f])
                 (stop (reverse result))
                 (if (null? l)
                     (set! stop #t)
                     (begin
                       (set! result
                             (cons (let ((var (car l)))
                                     body ...)
                                   result))
                       (set! l (cdr l))))))))]))
(: generate-indices (∀ (T) (case→ (→ Integer (Syntax-Listof T) (Listof Integer))
                                  (→ (Syntax-Listof T) (Listof Nonnegative-Integer)))))
(define generate-indices
  (case-lambda
    [(start stx)
     (for/list ([v (my-in-syntax stx)]
                [i (in-naturals start)])
       i)]
    [(stx)
     (for/list ([v (my-in-syntax stx)]
                [i : Nonnegative-Integer (ann (in-naturals) (Sequenceof Nonnegative-Integer))])
       i)]))