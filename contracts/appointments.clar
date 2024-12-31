;; Define a map data structure
(define-map appointments uint (tuple (doctor principal) (user principal) (time uint)))

;; a variable to store appointment id
(define-data-var appointment-id uint u1)

;; Define errors
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_APPOINTMENT_NOT_FOUND (err u200))
(define-constant ERR_INVALID_APPOINTMENT (err u300))

;; Define constant for contract
(define-constant CONTRACT_OWNER tx-sender)

;; Placeholder for appointment fee in MEDtokens
(define-constant APPOINTMENT_REWARD u50)
(define-constant BOOK_APPOINTMENT_FEES u10)
;; (define-public (book-appointment (doctor principal) (time uint))
;;   (begin
;;     (let ((id (var-get appointment-id)))
;;       (var-set appointment-id (+ id u1))
;;       (map-set appointments id {doctor: doctor, user: tx-sender, time: time})
;;       (ok id)
;;     )
;;   )
;; )

;; #[allow(unchecked_data)]
(define-public (book-appointment (doctor principal) (time uint))
  (begin
    ;; (try! (contract-call? .medtoken transfer BOOK_APPOINTMENT_FEES tx-sender doctor none))
    (try! (contract-call? .activity-prices can-user-afford-activity tx-sender "consultation"))
    (try! (contract-call? .activity-prices pay-for-activity "consultation"))

    ;; Create the appointment
    (let ((id (var-get appointment-id)))
      (var-set appointment-id (+ id u1))
      (map-set appointments id {doctor: doctor, user: tx-sender, time: time})

       ;; Update user activities in the medtoken-rewards contract
      (try! (contract-call? .medtoken-rewards record-user-activity tx-sender "consultation"))
      (ok id)
    )
  )
)

(define-public (cancel-appointment (id uint))
  (begin
    (let ((appointment (map-get? appointments id)))
      (asserts! (is-some appointment) ERR_APPOINTMENT_NOT_FOUND)
      (asserts! (is-eq (get user (unwrap! appointment ERR_INVALID_APPOINTMENT)) tx-sender) ERR_NOT_AUTHORIZED)
      (map-delete appointments id)
      (ok true)
    )
  )
)

(define-read-only (get-appointment (id uint))
  (ok (map-get? appointments id))
)

(define-public (complete-appointment (id uint))
  (begin
    (let ((appointment (map-get? appointments id)))
      (asserts! (is-some appointment) ERR_APPOINTMENT_NOT_FOUND)

      ;; Only the user who was recommended the drug can complete this recommendation
      (asserts! (is-eq (get user (unwrap-panic appointment)) tx-sender) ERR_NOT_AUTHORIZED)
      ;; Transfer tokens as reward
     ;;   (try! (contract-call? .medtoken transfer APPOINTMENT_REWARD CONTRACT_OWNER (get doctor (unwrap-panic appointment)) none))
      (try! (contract-call? .activity-prices pay-doctor-for-activity (get doctor (unwrap-panic appointment)) "consultation"))
      (try! (contract-call? .medtoken-rewards record-doctor-activity (get doctor (unwrap-panic appointment)) "consultation"))

      (ok u0) ;;
    )
  )
)