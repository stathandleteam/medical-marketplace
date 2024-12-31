
;; title: audit-logs
;; version:
;; summary:
;; description:

;; traits
;;

(define-map audit-logs uint {action: (string-utf8 50), admin: principal, timestamp: uint, details: (string-utf8 130)})
(define-data-var log-counter uint u0)
(define-data-var log-ids (list 200 uint) (list))
(define-constant ERR_EMPTY_ACTION (err u401))
(define-constant ERR_EMPTY_DETAILS (err u402))

;; Helper function to log admin actions
(define-public (log-admin-action (action (string-utf8 50)) (details (string-utf8 130)))
  (begin
;; Validate non-empty strings
    (asserts! (> (len action) u0) ERR_EMPTY_ACTION)
    (asserts! (> (len details) u0) ERR_EMPTY_DETAILS)
    (let (
        (log-id (var-get log-counter))
                (current-time (unwrap-panic (get-block-info? time u0)))

        )
      (var-set log-counter (+ log-id u1))
      

      (map-set audit-logs log-id {action: action, admin: tx-sender, timestamp: block-height, details: details})
      (var-set log-ids (unwrap-panic (as-max-len? (append (var-get log-ids) log-id) u200)))


    )
          (ok true)

  )
)

;; (define-public (log-admin-action (log-id uint) (action (string-utf8 50)) (details (string-utf8 100)))
;;   (begin
;;     (map-set audit-logs log-id {action: action, admin: tx-sender, timestamp: block-height, details: details})
;;     (ok true)
;;   )
;; )



(define-read-only (get-audit-logs)
  (let ((ids (var-get log-ids)))
    (ok (map fetch-log ids))
  )
)

(define-private (fetch-log (log-id uint))
  (default-to
    {action: u"", admin: tx-sender, timestamp: u0, details: u""}
    (map-get? audit-logs log-id))
)