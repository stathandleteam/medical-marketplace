
;; title: user-profile
;; version:
;; summary:
;; description:

(define-map users principal (tuple (name (string-utf8 50)) (email (string-utf8 50))  (is-approved bool)))
;; Define errors
(define-constant ERR_USER_ALREADY_APPROVED (err u101))
(define-constant ERR_USER_NOT_FOUND (err "USER NOT FOUND"))
(define-constant ERR_USER_NOT_APPROVED (err "USER_NOT_APPROVED"))
(define-constant ERR_USER_ALREADY_REGISTERED (err "USER ALREADY REGISTERED"))
(define-constant ERR_NOT_VALID_STRING_UTF8 (err "NOT_VALID_STRING_UTF8"))
(define-constant ERR_NOT_ADMIN (err "NOT ADMIN"))
(define-constant ERR_INVALID_NAME (err "INVALID NAME"))
(define-constant ERR_INVALID_SPECIALIZATION (err "INVALUD SPECIALIZATION"))
(define-constant ERR_UNAUTHORIZED (err "UNAUTHORIZED"))
(define-constant ERR_FAILED_TO_FETCH_ADMIN (err "FAILED TO FETCH ADMINS"))
(define-constant ERR_FAILED_TO_POST_AUDIT_LOGS (err "FAILED_TO_POST_AUDIT_LOGS"))
;; (define-constant ERR_FAILED_TO_ADD_USER_TO_ACTIVITIES (err "FAILED_TO_ADD_USER_TO_ACTIVITIES"))
(define-constant ERR_FAILED_TO_ADD_USER_TO_ACTIVITIES (err u300))
(define-constant ERR_INVALID_EMAIL (err "INVALID_EMAIL"))
(define-constant ERR_EMAIL_TOO_SHORT (err "EMAIL_TOO_SHORT"))

(define-data-var all-users (list 100 principal) (list))

(define-read-only (verify-admin (admin principal))
   (let ((admin-response (contract-call? .admin is-admin tx-sender)))
      (let ((is-admin-response (unwrap! admin-response ERR_FAILED_TO_FETCH_ADMIN))) ;; Unwrap the response
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


(define-private (validate-email (email (string-utf8 50)))
  (begin
    ;; Check that email is not empty and has minimum length (x@y.z)
    (asserts! (> (len email) u5) ERR_EMAIL_TOO_SHORT)
    
    ;; Check that email contains @ symbol
    (let ((at-pos (index-of email u"@")))
      (asserts! 
        (and
          ;; Must contain @
          (is-some at-pos)
          ;; Must contain . after @
          (is-some (index-of email u"."))
          ;; . must come after @
          (> (unwrap-panic (index-of email u".")) (unwrap-panic at-pos))
        ) 
        ERR_INVALID_EMAIL)
    )
    
    (ok true)
  )
)

(define-read-only (get-user (user principal))
  (ok (map-get? users user))
)

;; #[allow(unchecked_data)]
;; (define-public (register-user (name (string-utf8 50)) (email (string-utf8 50)))
;;   (begin
;;     (asserts! (is-none (map-get? users tx-sender)) ERR_USER_ALREADY_REGISTERED)
;;     (try! (validate-name name))
;;     (try! (validate-email email))
;;     (asserts! (not (is-eq (some name) none)) ERR_NOT_VALID_STRING_UTF8)
;;     (map-set users tx-sender {name: name, is-approved: true, email: email})
;;     (ok "User registered successfully")
;;   )
;; )

(define-read-only (get-all-users)
 (ok (var-get all-users))
)

;; Modify add-to-all-users to return a consistent response type with string-ascii
;; #[allow(unchecked_data)]
(define-public (add-to-all-users (user principal))
  (begin
    (let ((current-users (var-get all-users))
          (new-users (unwrap! (as-max-len? (append current-users user) u100) (err "List full"))))
      (var-set all-users new-users)
      (ok "User added to list")
    )
  )
)

;; #[allow(unchecked_data)]
(define-public (register-user (name (string-utf8 50)) (email (string-utf8 50)))
  (begin
    ;; Check if user is already registered
    (asserts! (is-none (map-get? users tx-sender)) ERR_USER_ALREADY_REGISTERED)
    
    ;; Validate input
    (try! (validate-name name))
    (try! (validate-email email))
    
    ;; Insert user into users map
    (map-set users tx-sender {name: name, is-approved: false, email: email}) ;; Set is-approved to false initially
    
    ;; Add user to index for payout tracking
    ;; (try! (contract-call? .medtoken-reward add-user-to-index tx-sender))
    (try! (add-to-all-users tx-sender)) ;; Adds user to all-users list

    ;; Send a notification or log the event
    (print {event: "User registration", user: tx-sender, name: name, email: email})
    
    (ok "User registered successfully, awaiting approval")
  )
)

;; #[allow(unchecked_data)]
(define-public (update-user-profile (name (string-utf8 50)) (email (string-utf8 50)))
  (begin

    ;; Ensure the doctor is registered and active
    (let ((user-info (map-get? users tx-sender)))
      (asserts! (is-some user-info) ERR_USER_NOT_FOUND)
      (try! (validate-name name))
      (try! (validate-email email))  

      (asserts! (get is-approved (unwrap! user-info ERR_USER_NOT_FOUND)) ERR_USER_NOT_APPROVED)
      ;; Update the profile
      (map-set users tx-sender {name: name, email: email, is-approved: (get is-approved (unwrap! user-info ERR_USER_NOT_APPROVED))})
      (ok "User profile updated successfully")
    )
  )
)


;; Admin function to approve a user
(define-public (approve-user (user principal))
  (begin
    (asserts! (is-ok (verify-admin tx-sender)) ERR_NOT_ADMIN)
    (let ((user-info (map-get? users user)))  ;; Check if user exists
      (asserts! (is-some user-info) ERR_USER_NOT_FOUND)
      (let ((is-approved (get is-approved (unwrap! user-info ERR_USER_NOT_FOUND))))
        (asserts! (is-eq is-approved false) ERR_USER_ALREADY_REGISTERED)  ;; Ensure user is not already approved
        (map-set users user {
            name: (get name (unwrap! user-info ERR_USER_ALREADY_REGISTERED)), 
            email: (get email (unwrap! user-info ERR_USER_ALREADY_REGISTERED)), 
            is-approved: true})

          ;; ;; Call to add-user-to-activities in medtoken-reward contract
          ;; (asserts! (is-ok (contract-call? .medtoken-rewards add-user-to-activities user)) ERR_FAILED_TO_ADD_USER_TO_ACTIVITIES)

        ;; Audit logging
        (let ((audit-msg (concat (concat u"Approve user: " (get name (unwrap! user-info ERR_USER_NOT_FOUND))) u"")))
          (asserts!
            (is-ok (contract-call? .audit-logs log-admin-action 
                u"User approved"
                audit-msg))
            ERR_FAILED_TO_POST_AUDIT_LOGS)
        )
        (ok "User approved")
      )
    )
  )
)


;; ;; Admin function to approve a user
;; (define-public (approve-user (user principal))
;;   (begin
;;     (asserts! (is-ok (verify-admin tx-sender)) ERR_NOT_ADMIN)
;;     (let ((user-info (map-get? users user)))  ;; Check if user exists
;;       (asserts! (is-some user-info) ERR_USER_NOT_FOUND)
;;       (let ((is-approved (get is-approved (unwrap! user-info ERR_USER_NOT_FOUND))))
;;         (asserts! (is-eq is-approved false) ERR_USER_ALREADY_REGISTERED)  ;; Ensure user is not already approved
;;         (map-set users user {
;;             name: (get name (unwrap! user-info ERR_USER_ALREADY_REGISTERED)), 
;;             email: (get email (unwrap! user-info ERR_USER_ALREADY_REGISTERED)), 
;;             is-approved: true})
        
;;         ;;  (try! (contract-call? .medtoken-rewards add-user-to-activities user))
;;   ;; Call to add-user-to-activities in medtoken-reward contract
;;            (asserts! (is-ok (contract-call? .medtoken-rewards add-user-to-activities user)) ERR_FAILED_TO_ADD_USER_TO_ACTIVITIES)
        
;;          (let ((audit-msg (concat (concat u"Approve user: " (get name (unwrap! user-info ERR_USER_NOT_FOUND))) u"")))
;;                 (asserts!
;;                 (is-ok (contract-call? .audit-logs log-admin-action 
;;                     u"User approved"
;;                     audit-msg))
;;                 ERR_FAILED_TO_POST_AUDIT_LOGS)
;;                 (ok "User approved"))

;;       )
;;     )
;;   )
;; )

;; Admin function to reject a user
(define-public (reject-user (user principal))
  (begin
    (asserts! (is-ok (verify-admin tx-sender)) ERR_NOT_ADMIN)
    (let ((user-info (map-get? users user)))  ;; Check if user exists
      (asserts! (is-some user-info) ERR_USER_NOT_FOUND)
      (map-delete users user)  ;; Reject the user by deleting from the map
    
        ;; Log the action in the audit logs contract
        (let ((audit-msg (concat (concat u"Reject user: " (get name (unwrap! user-info ERR_USER_NOT_FOUND))) u"")))
        (asserts!
        (is-ok (contract-call? .audit-logs log-admin-action 
            u"User rejected"
            audit-msg))
        ERR_FAILED_TO_POST_AUDIT_LOGS)
        (ok "User rejected"))

    )
  )
)

(define-read-only (is-user-approved (user principal))
  (let ((user-info (map-get? users user)))
    (if (is-some user-info)
        (ok (get is-approved (unwrap! user-info ERR_USER_ALREADY_APPROVED)))
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