;; title: drug-recommendation
;; version:
;; summary:
;; description:

(define-constant ERR_UNAUTHORIZED (err "Unauthorized"))
(define-constant ERR_FAILED_TO_FETCH_DOCTOR (err "Failed to fetch doctors"))
(define-constant ERR_NOT_DOCTOR (err "NOT DOCTOR"))
(define-map recommendations uint (tuple (doctor principal) (user principal) (drug (string-utf8 50)) (status (string-utf8 20))))
;; (define-map recommendations uint { doctor: principal, user: principal, drug: (string-utf8 50), status: (string-ascii 20) })

;; Assuming these error constants are defined elsewhere:
(define-constant ERR_RECOMMENDATION_NOT_FOUND u100)
(define-constant ERR_NOT_AUTHORIZED u101)

;; Define a constant for the reward amount for recommendations
(define-constant RECOMMENDATION_REWARD u50) ;; Example reward amount in MEDtokens

(define-data-var recommendation-id uint u1)

(define-constant TOKEN_DISTRIBUTOR tx-sender) ;; Or another address that holds tokens for distribution

(define-read-only (verify-doctor (doctor principal))
   ;; Call get-doctors and unwrap the response
    (let ((doctor-response (contract-call? .doctor-profile get-doctor doctor)))
      (let ((is-doctor (unwrap! doctor-response ERR_FAILED_TO_FETCH_DOCTOR))) ;; Unwrap the response

        ;; Ensure doctor is not none
        (asserts! (is-some is-doctor) ERR_UNAUTHORIZED)
        (ok true)
      )
    )
)

;; #[allow(unchecked_data)]
(define-public (recommend-drug (user principal) (drug (string-utf8 50)))
  (begin
    
        (asserts! (is-ok (verify-doctor tx-sender)) ERR_NOT_DOCTOR)
        ;; Generate the recommendation ID and store the recommendation
        (let ((id (var-get recommendation-id)))
          (var-set recommendation-id (+ id u1))
          (map-set recommendations id 
            { doctor: tx-sender, user: user, drug: drug, status: u"Pending" })
          (ok id)
        )
   
  )
)

;; Function to complete a doctor recommendation and reward the doctor
(define-public (complete-doctor-recommendation (recommendation_id uint))
  (begin
    (let ((recommendation (map-get? recommendations recommendation_id)))
      (asserts! (is-some recommendation) (err ERR_RECOMMENDATION_NOT_FOUND))
      ;; Only the user who was recommended the drug can complete this recommendation
      (asserts! (is-eq (get user (unwrap-panic recommendation)) tx-sender) (err ERR_NOT_AUTHORIZED))
      
      (try! (contract-call? .payment-methods pay-with-stx TOKEN_DISTRIBUTOR (get doctor (unwrap-panic recommendation)) RECOMMENDATION_REWARD))
       ;; Update user activities in the medtoken-rewards contract
      (try! (contract-call? .medtoken-rewards record-doctor-activity tx-sender "consultation"))
      
      ;; Optionally, update the status of the recommendation to completed
      (map-set recommendations recommendation_id 
        (merge (unwrap-panic recommendation) { status: u"Completed" }))
      
      (ok u0) ;; Return success
    )
  )
)


;; Map for storing recommendations (assuming it's defined elsewhere)
;; (define-map recommendations uint { doctor: principal, user: principal, drug: (string-utf8 50), status: (string-ascii 20) })

(define-read-only (get-recommendation (id uint))
  (ok (map-get? recommendations id))
)