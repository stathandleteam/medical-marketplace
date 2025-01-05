
;; title: activity-prices
;; version:
;; summary:
;; description:

(define-constant ERR_FAILED_TO_FETCH_ADMIN (err "FAILED TO FETCH DOCTORS"))
(define-constant ERR_UNAUTHORIZED (err "UNAUTHORIZED"))
(define-constant ERR_NOT_ADMIN (err "NOT ADMIN"))
(define-constant ERR_USER_CANT_AFFORD (err u100))
(define-constant TOKEN_DISTRIBUTOR tx-sender) ;; Or another address that holds tokens for distribution


(define-constant ERR_NO_PAYOUT (err u101))
(define-constant ERR_ACTIVITY_NOT_FOUND (err u102))

;; (define-map activity-prices (string-ascii 32) uint )
(define-map activity-prices (string-ascii 32) { price: uint, doctor-payout: uint })

(define-public (set-activity-price (activity (string-ascii 32)) (price uint) (doctor-payout uint))
  (begin
    ;; #[filter(activity, price, doctor-payout)]
    (try! (contract-call? .admin verify-admin tx-sender))
    (map-set activity-prices activity { price: price, doctor-payout: doctor-payout })
    (ok true)
  )
)

(define-read-only (get-activity (activity (string-ascii 32)))
  (ok (default-to { price: u0, doctor-payout: u0 } (map-get? activity-prices activity)))
)

(define-read-only (get-activity-price (activity (string-ascii 32)))
  (ok 
    (default-to u0 
      (get price (map-get? activity-prices activity))
    )
  )
)

(define-read-only (get-activity-doctor-payout (activity (string-ascii 32)))
  (ok 
    (default-to u0 
      (get doctor-payout (map-get? activity-prices activity))
    )
  )
)

(define-public (can-user-afford-activity (user principal) (activity (string-ascii 32)))
  (let (
    (user-balance (unwrap-panic (contract-call? .payment-methods get-balance user)))
    (activity-price (unwrap-panic (get-activity-price activity)))
  )
    (asserts! (>= user-balance activity-price) ERR_USER_CANT_AFFORD) ;; Error code assuming user can't afford
    (ok true) ;; User can afford the activity
  )
)

;; Let's say we want to check the price for a "consultation"
(define-public (check-consultation-price)
  (begin
    (let ((consultation-price (unwrap-panic (get-activity-price "consultation"))))
      (print consultation-price)
    )
    (ok true)
  )
)

(define-public (pay-for-activity (activity (string-ascii 32)))
  (let ((price (unwrap! (get-activity-price activity) (err u102))))
    (asserts! (> price u0) ERR_NO_PAYOUT)
    (try! (contract-call? .payment-methods pay-with-stx tx-sender TOKEN_DISTRIBUTOR price))
    (ok "Payment successful")
  )
)

;; Function to pay doctors for activity completion
(define-public (pay-doctor-for-activity (doctor principal) (activity (string-ascii 32)))
 
 (let ((doctor-payout (unwrap! (get-activity-doctor-payout activity) (err u102))))
    (asserts! (> doctor-payout u0) ERR_NO_PAYOUT)
    (try! (contract-call? .payment-methods pay-with-stx tx-sender TOKEN_DISTRIBUTOR doctor-payout))
    (ok "Payment successful")
  )

;;   (let (
;;     (activity-info (unwrap! (get-activity activity) ERR_ACTIVITY_NOT_FOUND))
;;     (doctor-payout (get doctor-payout activity-info))
;;   )
;;     ;; Ensure there's an actual payout for this activity
;;     (asserts! (> doctor-payout u0) ERR_NO_PAYOUT)
;;     ;; Make the payment to the doctor
;;     ;; (try! (contract-call? .payment-methods pay-with-stx TOKEN_DISTRIBUTOR doctor doctor-payout))    
;;     (ok true)
;;   )
)

;; Function to handle STX payment for appointments
;; (define-public (pay-with-stx-for-appointment (appointment-id uint) (amount-stx uint))
;;   (begin
;;     ;; Assume there's a function or map to get the price in STX for an appointment
;;     (let ((appointment-price (unwrap-panic (get-appointment-price appointment-id))))
;;       (asserts! (>= amount-stx appointment-price) (err u104)) ;; Not enough STX paid
;;       ;; Transfer STX from user to contract or doctor (assuming contract holds for later distribution)
;;       (try! (stx-transfer? amount-stx tx-sender (as-contract tx-sender)))
;;       (ok true)
;;     )
;;   )
;; )

;; ;; Function to pay doctors in STX
;; ;; #[allow(unchecked_data)]
;; (define-public (pay-doctor-stx (doctor principal) (amount-stx uint))
;;   (begin
;;     ;; Check if the contract has enough STX
;;     (asserts! (>= (stx-get-balance (as-contract tx-sender)) amount-stx) (err u105)) ;; Contract doesn't have enough STX
;;     ;; Transfer STX to the doctor
;;     (try! (as-contract (stx-transfer? amount-stx TOKEN_DISTRIBUTOR doctor)))
;;     (ok true)
;;   )
;; )

;; ;; Function to reward with MEDToken after STX payment is processed
;; (define-public (reward-medtoken (recipient principal) (amount uint))
;;   (begin
;;     ;; Only the contract can call this to reward after STX transactions
;;     (asserts! (is-eq tx-sender (as-contract tx-sender)) (err u106)) ;; Unauthorized
;;     (try! (mint-for-marketplace recipient amount))
;;     (ok true)
;;   )
;; )

;; Usage 
;; set-activity-price
;; (set-activity-price "consultation" u1000000 u500000)  // { price: u0, doctor-payout: u0 }

;; get-activity
;; (get-activity "consultation")  //(ok u1000000)

;; Or for a user-facing application (pseudo-code interaction):
;; - A user interface in an app or web page would call this function like:

;; Response = callReadOnlyFunction("your-contract-address", "get-activity-price", ["consultation"])
;; If Response is successful, parse the price from the response and display it


;; Usage for set-activity-price
;; Setting a price and payout for a consultation activity
;; -> (set-activity-price "consultation" u1000000 u500000) ;; Sets price at 1 STX with a 0.5 STX payout to doctors

;; Usage for verify-admin
;; Assuming 'SP...ADMIN_ADDRESS...' is the address of an admin
;; -> (verify-admin 'SP...ADMIN_ADDRESS...)

;; Usage for get-activity
;; Fetching details of an activity
;; -> (get-activity "consultation")

;; Usage for get-activity-price
;; Getting just the price of an activity
;; -> (get-activity-price "consultation")

;; Usage for can-user-afford-activity
;; Checking if a user can afford a consultation
;; Assuming 'SP...USER_ADDRESS...' is the address of a user
;; -> (can-user-afford-activity 'SP...USER_ADDRESS... "consultation")

;; Usage for check-consultation-price
;; Checking and printing the price for a consultation
;; -> (check-consultation-price)

;; Usage for pay-for-activity
;; Paying for an activity (consultation in this case)
;; -> (pay-for-activity "consultation")

;; Usage for pay-doctor-for-activity
;; Paying a doctor for completing an activity
;; Assuming 'SP...DOCTOR_ADDRESS...' is the address of a doctor
;; -> (pay-doctor-for-activity 'SP...DOCTOR_ADDRESS... "consultation")