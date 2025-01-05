
;; title: medtoken-rewards
;; version:
;; summary:
;; description:

;; Track user activity
(define-map user-activities principal { consultations: uint, prescriptions: uint })
(define-map doctor-activities principal { consultations: uint, prescriptions: uint })

;; Constants for user payout thresholds
(define-constant USER_CONSULTATIONS_THRESHOLD u5)
(define-constant USER_PRESCRIPTIONS_THRESHOLD u3)

;; Constants for doctor payout thresholds
(define-constant DOCTOR_CONSULTATIONS_THRESHOLD u10)
(define-constant DOCTOR_PRESCRIPTIONS_THRESHOLD u5)

(define-constant TOKEN_DISTRIBUTOR tx-sender) ;; Or another address that holds tokens for distribution

;; New function to add a user to user-activities map
(define-public (add-user-to-activities (user principal))
  (begin
    ;; (asserts! (is-ok  (contract-call? .user-profile is-user-approved user)) (err u200)) ;; User not approved
    ;; (let ((approval-result (contract-call? .user-profile is-user-approved user)))
    ;;   (match approval-result
    ;;     approval (asserts! approval (err u200)) ;; If 'ok', check if the user is approved
    ;;     error-code (asserts! false (err u200)) ;; If 'err', treat it as not approved
    ;;   )
    ;; )
    (asserts! (is-none (map-get? user-activities user)) (err u201)) ;; User already exists
    (map-insert user-activities user { consultations: u0, prescriptions: u0 })
    (ok true)
  )
)

;; New function to add a user to user-activities map
(define-public (add-doctor-to-activities (doctor principal))
  (begin
    ;; (asserts! (is-ok (contract-call? .doctor-profile is-doctor-approved doctor)) (err u200)) ;; doctor not approved

    ;; (let ((approval-result (contract-call? .doctor-profile is-doctor-approved doctor)))
    ;;   (match approval-result
    ;;     approval (asserts! approval (err u200)) ;; If 'ok', check if the user is approved
    ;;     error-code (asserts! false (err u200)) ;; If 'err', treat it as not approved
    ;;   )
    ;; )
    (asserts! (is-none (map-get? doctor-activities doctor)) (err u201)) ;; doctor already exists
    (map-insert doctor-activities doctor { consultations: u0, prescriptions: u0 })
    (ok true)
  )
)

;; Function to record a consultation for a user
;; #[allow(unchecked_data)]
;; (define-public (record-user-activity (user principal) (activity-type (string-ascii 32)))
;;   (let (
;;     (current-activity (unwrap! (map-get? user-activities user) (err u100)))
;;     (new-activity 
;;       (if (is-eq activity-type "consultation")
;;         (ok { consultations: (+ (get consultations current-activity) u1), prescriptions: (get prescriptions current-activity) })
;;         (if (is-eq activity-type "prescription")
;;           (ok { consultations: (get consultations current-activity), prescriptions: (+ (get prescriptions current-activity) u1) })
;;           (err u101) ;; Activity type not recognized
;;         )
;;       )
;;     )
;;   )
;;     ;; Update the user's activity based on the type
;;     (match new-activity
;;       activity (begin
;;         (map-set user-activities user (merge current-activity activity))
;;         (ok true))
;;       error-code (err error-code)
;;     )
;;   )
;; )

;; In medtoken-rewards contract

;; Define the principal of the appointment contract
;; #[allow(unchecked_data)]
(define-public (record-user-activity (user principal) (activity-type (string-ascii 32)))
  (begin
    ;; Check if the caller is the appointment contract
    ;; (asserts! (is-eq contract-caller .appointment) (err u300)) ;; Error if not called by appointment contract

    (let (
      (current-activity (default-to { consultations: u0, prescriptions: u0 } (map-get? user-activities user)))
      (new-activity 
        (if (is-eq activity-type "consultation")
          (ok { consultations: (+ (get consultations current-activity) u1), prescriptions: (get prescriptions current-activity) })
          (if (is-eq activity-type "prescription")
            (ok { consultations: (get consultations current-activity), prescriptions: (+ (get prescriptions current-activity) u1) })
            (err u101) ;; Activity type not recognized
          )
        )
      )
    )
      ;; Update or insert the user's activity based on the type
      (match new-activity
        activity (begin
          (map-set user-activities user activity)
          (ok true))
        error-code (err error-code)
      )
    )
  )
)
;; Function to record a consultation for a doctor
;; #[allow(unchecked_data)]
(define-public (record-doctor-activity (doctor principal) (activity-type (string-ascii 32)))

  (begin
    ;; Check if the caller is the appointment contract
    ;; (asserts! (or (is-eq contract-caller .drug-recommendation) (is-eq contract-caller .appointment)) (err u300)) ;; Error if not called by appointment contract

  (let 
  
;;   (
;;     (current-activity (unwrap! (map-get? doctor-activities doctor) (err u100)))
;;     (new-activity 
;;       (if (is-eq activity-type "consultation")
;;         (ok { consultations: (+ (get consultations current-activity) u1), prescriptions: (get prescriptions current-activity) })
;;         (if (is-eq activity-type "prescription")
;;           (ok { consultations: (get consultations current-activity), prescriptions: (+ (get prescriptions current-activity) u1) })
;;           (err u101) ;; Activity type not recognized
;;         )
;;       )
;;     )
;;   )

 (
      (current-activity (default-to { consultations: u0, prescriptions: u0 } (map-get? doctor-activities doctor)))
      (new-activity 
        (if (is-eq activity-type "consultation")
          (ok { consultations: (+ (get consultations current-activity) u1), prescriptions: (get prescriptions current-activity) })
          (if (is-eq activity-type "prescription")
            (ok { consultations: (get consultations current-activity), prescriptions: (+ (get prescriptions current-activity) u1) })
            (err u101) ;; Activity type not recognized
          )
        )
      )
    )

    ;; Update the user's activity based on the type
    (match new-activity
      activity (begin
        (map-set doctor-activities doctor (merge current-activity activity))
        (ok true))
      error-code (err error-code)
    )


  )
  )
)


;; Payout function for users
;; #[allow(unchecked_data)]
(define-public (automatic-user-payout (user principal))
  (let (
    (user-activity (default-to { consultations: u0, prescriptions: u0 } (map-get? user-activities user)))
    (consultations (get consultations user-activity))
    (prescriptions (get prescriptions user-activity))
    (total-reward (+ 
      (* consultations u1000000) ;; 1 MEDtoken per consultation in smallest unit
      (* prescriptions u500000) ;; 0.5 MEDtoken per prescription in smallest unit
    ))
  )
    ;; Check if user has met criteria
    (asserts! (or (>= consultations USER_CONSULTATIONS_THRESHOLD) 
                  (>= prescriptions USER_PRESCRIPTIONS_THRESHOLD)) 
              (err u100)) ;; User does not meet criteria for payout

    ;; Perform the payout
    (try! (contract-call? .medtoken transfer total-reward TOKEN_DISTRIBUTOR user none))
    
    ;; Reset the user's activity count after payout
    (map-set user-activities user { consultations: u0, prescriptions: u0 })
    
    (ok total-reward)
  )
)


;; Payout function for doctors (similar logic but different thresholds)
;; #[allow(unchecked_data)]
(define-public (automatic-doctor-payout (doctor principal))
  (let (
    (doctor-activity (default-to { consultations: u0, prescriptions: u0 } (map-get? doctor-activities doctor)))
    (consultations (get consultations doctor-activity))
    (prescriptions (get prescriptions doctor-activity))
    (total-reward (+ 
      (* consultations u2000000) ;; 2 MEDtoken per consultation for doctors in smallest unit
      (* prescriptions u1000000) ;; 1 MEDtoken per prescription for doctors in smallest unit
    ))
  )
    ;; Check if doctor has met criteria
    (asserts! (or (>= consultations DOCTOR_CONSULTATIONS_THRESHOLD) 
                  (>= prescriptions DOCTOR_PRESCRIPTIONS_THRESHOLD)) 
              (err u101)) ;; Doctor does not meet criteria for payout

    ;; Perform the payout
    (try! (contract-call? .medtoken transfer total-reward TOKEN_DISTRIBUTOR doctor none))
    
    ;; Reset the doctor's activity count after payout
    (map-set doctor-activities doctor { consultations: u0, prescriptions: u0 })
    
    (ok total-reward)
  )
)

;; In medtoken-rewards.clar

;; Function to process payouts for all users and doctors who qualify
(define-public (process-all-qualified-payouts)
  (begin
    ;; Verify admin status
    (try! (contract-call? .admin verify-admin tx-sender))
    
    ;; Fetch users and doctors
    (let ((users (unwrap-panic (contract-call? .user-profile get-all-users)))
          (doctors (unwrap-panic (contract-call? .doctor-profile get-all-doctors))))
      ;; Process payouts for each user
      (map process-user-payout users)
      ;; Process payouts for each doctor
      (map process-doctor-payout doctors)
    )
    (ok true)
  )
)

;; Private helper function to process payout for a single user
(define-private (process-user-payout (user principal))
  (let ((result (automatic-user-payout user)))
    (match result
      success (begin
        (print { user: user, outcome: "Success", reward: success })
        (ok true))
      error (begin
        (print { user: user, outcome: "Error", error-code: error })
        (ok false))
    )
  )
)

;; Private helper function to process payout for a single doctor
(define-private (process-doctor-payout (doctor principal))
  (let ((result (automatic-doctor-payout doctor)))
    (match result
      success (begin
        (print { doctor: doctor, outcome: "Success", reward: success })
        (ok true))
      error (begin
        (print { doctor: doctor, outcome: "Error", error-code: error })
        (ok false))
    )
  )
)
