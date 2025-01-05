
;; title: procurement
;; version:
;; summary:
;; description:

;; traits
;;
(define-constant CONTRACT_OWNER tx-sender)

;; Define errors

(define-constant ERR_DRUG_STR_LEN_TOO_SHORT (err u1))
(define-constant ERR_DRUG_STR_LEN_TOO_LONG (err u2))
(define-constant ERR_UNAUTHORIZED (err "Unauthorized"))
(define-constant ERR_FAILED_TO_VERIFY_ADMIN (err "Failed to verify admin"))
(define-constant ERR_ORDER_NOT_FOUND (err "Order not found"))
(define-constant ERR_FAILED_TO_FETCH_DOCTOR (err "FAILED TO FETCH DOCTORS"))
(define-constant ERR_NOT_ADMIN (err "NOT ADMIN"))
(define-constant ERR_FAILED_TO_POST_AUDIT_LOGS (err "FAILED TO FETCH DOCTORS"))

(define-map orders uint (tuple (user principal) (drug (string-utf8 100)) (status (string-ascii 20))))

(define-data-var order-id uint u1)

(define-private (get-error-code (length uint))
  (if (< length u1)
    ERR_DRUG_STR_LEN_TOO_SHORT  
    ERR_DRUG_STR_LEN_TOO_LONG 
  )
)

(define-read-only (verify-admin (admin principal))
   (let ((doctors-response (contract-call? .admin is-admin tx-sender)))
      (let ((is-admin-response (unwrap! doctors-response ERR_FAILED_TO_FETCH_DOCTOR))) ;; Unwrap the response
        ;; Ensure doctors is not none
        (asserts! (is-some is-admin-response) ERR_UNAUTHORIZED)
        (ok true)
      )
    )
)

(define-public (place-order (drug (string-utf8 50)) (price uint))
    (begin
        (asserts! (and (>= (len drug) u1) (<= (len drug) u50)) (get-error-code (len drug)))
        (match (contract-call? .medtoken transfer price tx-sender CONTRACT_OWNER none)
            success (let ((id (var-get order-id)))
                (var-set order-id (+ id u1))
                (map-set orders id {user: tx-sender, drug: drug, status: "Pending"})
                (ok id))
            error (err u2))))



;; #[allow(unchecked_data)]
(define-public (update-order-status (id uint) (status (string-utf8 20)))
  (begin
    ;; Call the external contract to check admin status
        (asserts! (is-ok (verify-admin tx-sender)) ERR_NOT_ADMIN)

        ;; Update the order status if it exists
        (map-set orders id
          (merge {status: status} (unwrap! (map-get? orders id) (err "Order not found"))))
        
         (let ((audit-msg (concat (concat u"update-order-status: Id - " (int-to-utf8 (to-int id))) (concat u"Status - " status ))))
                (asserts!
                (is-ok (contract-call? .audit-logs log-admin-action 
                    u"Order updated"
                    audit-msg))
                ERR_FAILED_TO_POST_AUDIT_LOGS)
                (ok "Order Status updated"))
  )
)

(define-read-only (get-order (id uint))
  (ok (map-get? orders id))
)