;; title: payment-methods
;; version: v1.0
;; summary: Payment operations for MEDtoken
;; description: This contract handles payment operations using MEDtoken and STX.

(define-constant ERR_INSUFFICIENT_BALANCE (err u103))
(define-constant ERR_INSUFFICIENT_STX (err u104))
;; Define constant for contract
(define-constant CONTRACT_OWNER tx-sender)

;; Example for payment function that accepts fractional tokens
(define-public (make-payment-with-med (sender principal) (recipient principal) (amount uint))
  (begin
    ;; amount is in smallest unit (millionths of a token)
    ;; e.g. amount = 500000 means 0.5 MEDtoken
    (try! (contract-call? .medtoken transfer amount sender recipient none))
    (ok amount)
  )
)

;; Function to pay with STX
;; #[allow(unchecked_data)]
(define-public (pay-with-stx (sender principal) (recipient principal) (amount uint))
  (begin
    (asserts! (>= (stx-get-balance sender) amount) ERR_INSUFFICIENT_STX)
    (stx-transfer? amount sender recipient)
  )
)

;; Read-only function to get the owner's balance
(define-read-only (get-balance (who principal))
  (ok (stx-get-balance who))
)