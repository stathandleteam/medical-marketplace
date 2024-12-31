
;; (define-map admins principal bool)
(define-map admins principal 
  {
    role: (string-utf8 50),
    added-by: principal,
    added-at: uint
  }
)

;; Define errors
(define-constant ERR_NOT_ADMIN (err "NOT ADMIN"))
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_VALID_PRINCIPAL (err u300))
(define-constant ERR_ROLE_NOT_FOUND (err "ROLE_NOT_FOUND"))
(define-constant ERR_NOT_AUTHORIZED (err "NOT_AUTHORIZED"))
(define-constant ERR_FAILED_TO_POST_AUDIT_LOGS (err "FAILED_TO_POST_AUDIT_LOGS"))
(define-constant ERR_FAILED_TO_FETCH_DOCTOR (err u400))

;; Define constant for contract
(define-constant CONTRACT_OWNER tx-sender)
;; Assuming there's an initial supply of tokens held by CONTRACT_OWNER or another designated address
(define-constant TOKEN_DISTRIBUTOR CONTRACT_OWNER) ;; Or another address that holds tokens for distribution
(define-constant ADMIN_LIST (list CONTRACT_OWNER))

;; Constants for role names
(define-constant SUPER_ADMIN u"super-admin")
(define-constant DOCTOR_ADMIN u"doctor-admin")



(define-public (add-super-admin (admin principal))
  (begin
    (asserts! (is-eq contract-caller CONTRACT_OWNER) ERR_UNAUTHORIZED)
     ;; Ensure the caller is a super-admin
    ;; (asserts! (verify-role tx-sender SUPER_ADMIN) ERR_NOT_ADMIN)
    (asserts! (not (is-eq (some admin) none)) ERR_NOT_VALID_PRINCIPAL)
     (map-set admins admin {role: SUPER_ADMIN,
        added-by: tx-sender,
        added-at: (unwrap-panic (get-block-info? time u0))
        })
    (ok true)
  )
)

;; Helper function to verify admin's role
(define-read-only (verify-role (admin principal) (role (string-utf8 50)))
  (let ((admin-role (map-get? admins admin)))
    (asserts! (is-some admin-role) ERR_NOT_ADMIN)
    (let ((role-name (get role (unwrap! admin-role ERR_ROLE_NOT_FOUND))))
        (ok (is-eq role-name role))
    )
  )
)

;; Admin function to register a new admin (with role)
;; #[allow(unchecked_data)]
(define-public (add-admin (admin principal) (role (string-utf8 50)))
  (begin
    ;; Ensure the caller is a super-admin
    (try! (verify-role tx-sender SUPER_ADMIN))
    ;; Check if the role is valid
    (asserts! (or (is-eq role SUPER_ADMIN) (is-eq role DOCTOR_ADMIN)) ERR_NOT_AUTHORIZED)
    (map-set admins admin {role: role,
    added-by: tx-sender,
      added-at: (unwrap-panic (get-block-info? time u0))
    })

   (let ((audit-msg (concat (concat u"Added admin with role: " role) u"")))
     (asserts!
       (is-ok (contract-call? .audit-logs log-admin-action 
         u"Add admin"
         audit-msg))
       ERR_FAILED_TO_POST_AUDIT_LOGS)
     (ok true))
  )
)


;; (define-public (add-admin (admin (optional principal)))
;;   (begin
;;     ;; Ensure the caller is the CONTRACT_OWNER
;;     (asserts! (is-eq contract-caller CONTRACT_OWNER) ERR_UNAUTHORIZED)
;;     ;; Assert that admin is not none
;;     (asserts! (is-some admin) ERR_NOT_VALID_PRINCIPAL)
;;     ;; Extract the principal from the optional
;;     (let ((some-admin (unwrap! admin ERR_NOT_VALID_PRINCIPAL)))
;;       ;; Add the admin to the map
;;       (map-set admins some-admin true)
;;       (ok true)
;;     )
;;   )
;; )

;; #[allow(unchecked_data)]
(define-public (remove-admin (admin principal))
  (begin
    (try! (verify-role tx-sender SUPER_ADMIN))
    (map-delete admins admin)
     (ok true)
  )
)

(define-read-only (is-admin (admin principal))
  (ok (map-get? admins admin))
)

;; Function to distribute tokens from a pre-existing supply
(define-public (distribute-tokens (recipient principal) (amount uint))
  (begin
    ;; (asserts! (is-ok (verify-admin tx-sender)) ERR_NOT_ADMIN)
    ;; Transfer tokens from the distributor to the recipient

    (let ((doctors-response (is-admin tx-sender)))
      (let ((is-admin-response (unwrap! doctors-response ERR_FAILED_TO_FETCH_DOCTOR))) ;; Unwrap the response
        ;; Ensure doctors is not none
        (asserts!  (or (is-some is-admin-response) (is-eq contract-caller tx-sender)) ERR_UNAUTHORIZED)
        
        (try! (contract-call? .medtoken transfer amount TOKEN_DISTRIBUTOR recipient none))
      )
    )
    (ok true)
  )
)

(define-read-only (verify-admin (admin principal))
   (let ((doctors-response (is-admin tx-sender)))
      (let ((is-admin-response (unwrap! doctors-response ERR_FAILED_TO_FETCH_DOCTOR))) ;; Unwrap the response
        ;; Ensure doctors is not none
        (asserts! (is-some is-admin-response) ERR_UNAUTHORIZED)
        (ok true)
      )
    )
)
