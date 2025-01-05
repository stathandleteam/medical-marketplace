
;; title: doctor-profile
;; version:
;; summary:
;; description:

;; traits
;;

(define-map pending-doctors principal {name: (string-utf8 50), specialization: (string-utf8 50)})
(define-map doctors principal {name: (string-utf8 50), specialization: (string-utf8 50), is-active: bool})


;; Define errors
(define-constant ERR_NOT_ADMIN (err "NOT ADMIN"))
(define-constant ERR_DOCTOR_ALREADY_REGISTERED (err "DOCTOR ALREADY REGISTERED"))
(define-constant ERR_INVALID_NAME (err "INVALID NAME"))
(define-constant ERR_INVALID_SPECIALIZATION (err "INVALUD SPECIALIZATION"))
(define-constant ERR_UNAUTHORIZED (err "UNAUTHORIZED"))
(define-constant ERR_FAILED_TO_FETCH_DOCTOR (err "FAILED TO FETCH DOCTORS"))

(define-constant ERR_DOCTOR_PENDING (err "DOCTOR_PENDING"))
(define-constant ERR_DOCTOR_NOT_PENDING (err "DOCTOR_NOT_PENDING"))
(define-constant ERR_DOCTOR_NOT_FOUND (err "DOCTOR_NOT_FOUND"))
(define-constant ERR_IS_ACTIVE_NOT_EXIST (err "IS_ACTIVE_NOT_EXIST"))
(define-constant ERR_NAME_NOT_EXIST (err "NAME_NOT_EXIST"))
(define-constant ERR_SPECIALIZATION_NOT_EXIST (err "SPECIALIZATION_NOT_EXIST"))
(define-constant ERR_DOCTOR_INACTIVE (err "DOCTOR_INACTIVE"))
(define-constant ERR_FAILED_TO_POST_AUDIT_LOGS (err "FAILED TO FETCH DOCTORS"))
(define-constant ERR_DOCTOR_ALREADY_APPROVED (err u101))

(define-data-var all-doctors (list 100 principal) (list))

(define-read-only (verify-admin (admin principal))
   (let ((admin-response (contract-call? .admin is-admin tx-sender)))
      (let ((is-admin-response (unwrap! admin-response ERR_FAILED_TO_FETCH_DOCTOR))) ;; Unwrap the response
        ;; Ensure admin is not none
        (asserts! (is-some is-admin-response) ERR_UNAUTHORIZED)
        (ok true)
      )
    )
)

(define-private (validate-name (name (string-utf8 50)))
  (begin
    (asserts! (> (len name) u0) ERR_INVALID_NAME)
    (ok true)
  )
)

;; Private helper function: Validate doctor specialization
(define-private (validate-specialization (specialization (string-utf8 50)))
  (begin
    (asserts! (> (len specialization) u0) ERR_INVALID_SPECIALIZATION)
    (ok true)
  )
)

(define-read-only (get-all-doctors)
 (ok (var-get all-doctors))
)

;; Modify add-to-all-users to return a consistent response type with string-ascii
;; #[allow(unchecked_data)]
(define-public (add-to-all-doctors (doctor principal))
  (begin
    (let ((current-doctors (var-get all-doctors))
          (new-doctors (unwrap! (as-max-len? (append current-doctors doctor) u100) (err "List full"))))
      (var-set all-doctors new-doctors)
      (ok "Doctors added to list")
    )
  )
)

;; Admin function to approve or reject new doctor registrations
(define-public (approve-doctor (doctor principal) (approve bool))
  (begin
    (asserts! (is-ok (verify-admin tx-sender)) ERR_NOT_ADMIN)
    ;; Check if the doctor is pending approval
    (let ( 
        (doctor-info (map-get? pending-doctors doctor))
    )
      (asserts! (is-some doctor-info) ERR_DOCTOR_NOT_PENDING)
      
      (if (is-eq approve true)
          (begin
            ;; Move the doctor to active doctors map
            (map-set doctors doctor {name: (get name (unwrap! doctor-info ERR_DOCTOR_NOT_FOUND)), 
                                     specialization: (get specialization (unwrap! doctor-info ERR_INVALID_SPECIALIZATION)),
                                     is-active: true})
            ;; Remove from pending doctors map
            (map-delete pending-doctors doctor)

            ;;     (ok "Doctor approved and registered")
            (let ((audit-msg (concat (concat u"Approve-doctor: " (get name (unwrap! doctor-info ERR_DOCTOR_NOT_FOUND)) ) u"")))

            (try! (add-to-all-doctors tx-sender)) ;; Adds doctors to all-users list

            (asserts!
            (is-ok (contract-call? .audit-logs log-admin-action 
                u"Doctor approved and registered"
                audit-msg))
            ERR_FAILED_TO_POST_AUDIT_LOGS)
            (ok "Doctor approved and registered"))
          )
          (begin
            ;; Remove from pending doctors map if rejected
            (map-delete pending-doctors doctor)

            (let ((audit-msg (concat (concat u"Approve-doctor: " (get name (unwrap! doctor-info ERR_DOCTOR_NOT_FOUND))) u"")))
                (asserts!
                (is-ok (contract-call? .audit-logs log-admin-action 
                    u"Doctor registration rejected"
                    audit-msg))
                ERR_FAILED_TO_POST_AUDIT_LOGS)
                (ok "Doctor registration rejected"))
            ;; (ok "Doctor registration rejected")
          )
      )
    )
  )
)

;; #[allow(unchecked_data)]
(define-public (register-doctor (name (string-utf8 50)) (specialization (string-utf8 50)))
  (begin
        ;; Ensure the doctor is not already registered or pending
        (asserts! (is-none (map-get? doctors tx-sender)) ERR_DOCTOR_ALREADY_REGISTERED)
        (asserts! (is-none (map-get? pending-doctors tx-sender)) ERR_DOCTOR_ALREADY_REGISTERED)

        (try! (validate-name name))
        (try! (validate-specialization specialization))
        (map-set pending-doctors tx-sender {name: name, specialization: specialization})
        (ok "Doctor registered successfully. Awaiting admin approval.")
    )
)

;; #[allow(unchecked_data)]
(define-public (update-doctor-profile (name (string-utf8 50)) (specialization (string-utf8 50)))
  (begin
    ;; Ensure the doctor is registered and active
    (let (
        (doctor-info (map-get? doctors tx-sender))
        (pending-doctor-info (map-get? pending-doctors tx-sender))
    )
      (asserts! (is-none pending-doctor-info) ERR_DOCTOR_PENDING)
      (asserts! (is-some doctor-info) ERR_DOCTOR_NOT_FOUND)
      (asserts! (get is-active (unwrap! doctor-info ERR_IS_ACTIVE_NOT_EXIST)) ERR_DOCTOR_INACTIVE)
      
      ;; Update the profile
      (map-set doctors tx-sender {name: name, specialization: specialization, is-active: (get is-active (unwrap! doctor-info ERR_IS_ACTIVE_NOT_EXIST))})
      (ok "Doctor profile updated successfully")
    )
  )
)

;; Admin function to suspend/deactivate a doctor profile
(define-public (suspend-doctor (doctor principal))
  (begin
    (asserts! (is-ok (verify-admin tx-sender)) ERR_NOT_ADMIN)
    ;; Ensure the doctor exists and is active
    (let ((doctor-info (map-get? doctors doctor)))
      (asserts! (is-some doctor-info) ERR_DOCTOR_NOT_FOUND)
      (asserts! (get is-active (unwrap! doctor-info ERR_IS_ACTIVE_NOT_EXIST)) ERR_DOCTOR_INACTIVE)
      
      ;; suspend the doctor
      (map-set doctors doctor {name: (get name (unwrap! doctor-info ERR_NAME_NOT_EXIST)), 
                               specialization: (get specialization (unwrap! doctor-info ERR_SPECIALIZATION_NOT_EXIST)),
                               is-active: false})

    (let ((audit-msg (concat (concat u"Suspend doctor: " (get name (unwrap! doctor-info ERR_DOCTOR_NOT_FOUND))) u"")))
                (asserts!
                (is-ok (contract-call? .audit-logs log-admin-action 
                    u"Doctor profile suspended successfully"
                    audit-msg))
                ERR_FAILED_TO_POST_AUDIT_LOGS)
                (ok "Doctor profile suspended successfully"))
    )
  )
)

;; Admin function to remove a doctor (if no longer needed)
(define-public (remove-doctor (doctor principal))
  (begin
    ;; (asserts! (verify-role tx-sender SUPER_ADMIN) ERR_NOT_ADMIN)
        (asserts! (is-ok (verify-admin tx-sender)) ERR_NOT_ADMIN)

    (let ((doctor-info (map-get? doctors doctor)))
      (asserts! (is-some doctor-info) ERR_DOCTOR_NOT_FOUND)
      ;; Remove doctor from active map
      (map-delete doctors doctor)

     (let ((audit-msg (concat (concat u"Remove-doctor: " (get name (unwrap! doctor-info ERR_DOCTOR_NOT_FOUND))) u"")))
                (asserts!
                (is-ok (contract-call? .audit-logs log-admin-action 
                    u"Doctor removed"
                    audit-msg))
                ERR_FAILED_TO_POST_AUDIT_LOGS)
                (ok "Doctor removed"))
    )
  )
)

(define-read-only (get-doctor (doctor principal))
  (ok (map-get? doctors doctor))
)

(define-read-only (is-doctor-approved (doctor principal))
  (let ((doctor-info (map-get? doctors doctor)))
    (if (is-some doctor-info)
        (ok (get is-active (unwrap! doctor-info ERR_DOCTOR_ALREADY_APPROVED)))
        (err u103)  ;; User not found
    )
  )
)

;; (register-user "John Doe")

    ;; (approve-user 'SP1234567890ABCDEF1234567890ABCDEF123456789)

    ;; (reject-user 'SP1234567890ABCDEF1234567890ABCDEF123456789)


;; (register-doctor 'SP1234567890ABCDEF1234567890ABCDEF123456789 "Dr. Jane Doe" "Cardiology")

    ;; Error Scenarios:

    ;; If the name is empty:
    ;; (register-doctor "" "Cardiology")

    ;; If the specialization is empty:
    ;; (register-doctor "Dr. Jane Doe" "")

    ;; If the doctor is already registered:
    ;; (register-doctor 'SP1234567890ABCDEF1234567890ABCDEF123456789 "Dr. John Doe" "Cardiology")


;; (remove-doctor 'SP1234567890ABCDEF1234567890ABCDEF123456789)

