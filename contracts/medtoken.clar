;; title: medtoken
;; version: v1.0
;; summary: MEDtoken implementing the SIP-010 standard
;; description: This contract implements the SIP-010 fungible token standard for the MEDtoken.

(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; Define the FT, with no maximum supply
(define-fungible-token MEDtoken)

;; Define errors
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_TOKEN_OWNER (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u103))

;; Define constants for contract
(define-constant TOKEN_URI u"") ;; utf-8 string with token metadata host
(define-constant TOKEN_NAME "MEDtoken")
(define-constant TOKEN_SYMBOL "MEDT")
(define-constant TOKEN_DECIMALS u6) ;; 6 units displayed past decimal, e.g. 1.000_000 = 1 token

;; Constants to help with decimal handling
(define-constant ONE_TOKEN u1000000) ;; 1.000000 MEDtoken


;; Extra

(define-constant CONTRACT_OWNER tx-sender)

(define-constant ADMIN_LIST (list CONTRACT_OWNER))
(define-constant TOKEN_DISTRIBUTOR CONTRACT_OWNER) ;; Or another address that holds tokens for distribution

;; SIP-010 function: Get the token balance of a specified principal
(define-read-only (get-balance (who principal))
  (ok (ft-get-balance MEDtoken who))
)

;; SIP-010 function: Returns the total supply of fungible token
(define-read-only (get-total-supply)
  (ok (ft-get-supply MEDtoken))
)

;; SIP-010 function: Returns the human-readable token name
(define-read-only (get-name)
  (ok TOKEN_NAME)
)

;; SIP-010 function: Returns the symbol or "ticker" for this token
(define-read-only (get-symbol)
  (ok TOKEN_SYMBOL)
)

;; SIP-010 function: Returns number of decimals to display
(define-read-only (get-decimals)
  (ok TOKEN_DECIMALS)
)

;; SIP-010 function: Returns the URI containing token metadata
(define-read-only (get-token-uri)
  (ok (some TOKEN_URI))
)

;; Mint new tokens for the marketplace by admins or the contract after STX transactions
;; #[allow(unchecked_data)]
(define-public (mint)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (ft-mint? MEDtoken u1 CONTRACT_OWNER)
  )
)

(define-public (burn) 
  (begin 
    (asserts! (is-eq contract-caller .admin) ERR_OWNER_ONLY)
    (ft-burn? MEDtoken u1 tx-sender)
  )
)
;; SIP-010 function: Transfers tokens to a recipient
(define-public (transfer
  (amount uint)
  (sender principal)
  (recipient principal)
  (memo (optional (buff 34)))
)
  (begin
    ;; #[filter(amount, recipient)]
    (asserts! (or (is-eq tx-sender sender) (is-eq contract-caller sender)) ERR_NOT_TOKEN_OWNER)
    (asserts! (>= (unwrap-panic (get-balance sender)) amount) ERR_INSUFFICIENT_BALANCE)
    (try! (ft-transfer? MEDtoken amount sender recipient))
    (match memo to-print (print to-print) 0x)
    (ok true)
  )
)

;; Mint new tokens for the marketplace by the contract
;; #[allow(unchecked_data)]
(define-public (mint-for-marketplace (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (ft-mint? MEDtoken amount TOKEN_DISTRIBUTOR)
  )
)


;; Helper function to convert whole tokens to smallest unit
(define-read-only (tokens-to-units (tokens uint))
  (* tokens ONE_TOKEN))

;; Helper function to convert smallest unit to whole tokens (rounds down)
(define-read-only (units-to-tokens (units uint))
  (/ units ONE_TOKEN))