(use util.match)
(use srfi-1)

(define-macro (match-all t m . clauses)
  (let* {[clause (car clauses)]
         [p (car clause)]
         [e (cadr clause)]}
    `(map (lambda (ret) (apply (lambda ,(extract-pattern-variables p) ,e) ret)) (gen-match-results ,p ,m ,t))))

(define extract-pattern-variables
  (lambda (p)
    (match p
           (('val _) '())
           ((c . args)
            (concatenate (map extract-pattern-variables args)))
           ('_ '())
           (pvar `(,pvar))
           )))

(define-macro (gen-match-results p m t)
  `(processMStates (list (list 'MState (list (list ,p ,m ,t) ) {}))))

(define processMStates
  (lambda (mStates)
    (match mStates
           (() '())
           ((('MState '{} ret) . rs)
            (cons ret (processMStates rs)))
           ((('MState {[('val x) M t] . mStack} ret) . rs)
            undefined)
           ((('MState {['_ 'Something t] . mStack} ret) . rs)
            (processMStates (cons `(MState ,mStack ,ret) rs)))
           ((('MState {[pvar 'Something t] . mStack} ret) . rs)
            (processMStates (cons `(MState ,mStack ,(append ret `(,t))) rs)))
           ((('MState {[p m t] . mStack} ret) . rs)
            (let {[next-matomss (m p t)]}
              (processMStates (append (map (lambda (next-matoms) `(MState ,(append next-matoms mStack) ,ret)) next-matomss) rs))))
           )))

(define Something 'Something)

(define Eq
  (lambda (p t)
    (match p
           (('val x)
            (if (eq? x t)
                '(())
                '()))
           (pvar
            `(((,pvar Something ,t))))
           )))

(define Integer Eq)

(define List
  (lambda (M)
    (lambda (p t)
      (match p
             (('cons px py)
              (match t
                     (() '())
                     ((x . xs)
                      `(((,px ,M ,x) (,py ,(List M) ,xs)))
                      )))
             (('join px py)
              (map (lambda (xy) `((,px ,(List M) ,(car xy)) (,py ,(List M) ,(cadr xy))))
                   (unjoin t)))
             (('val x)
              (if (eq? x t)
                  '(())
                  '()))
             (pvar
              `(((,pvar Something ,t))))
             ))))

(define unjoin
  (lambda (xs)
    (unjoin-helper '() xs)))

(define unjoin-helper
  (lambda (ret xs)
    (match xs
           (() ret)
           ((y . ys)
            (cons `(() ,xs) (map (lambda (p) `(,(cons y (car p)) ,(cadr p))) (unjoin ys))))
           )))

(unjoin '(1 2 3))