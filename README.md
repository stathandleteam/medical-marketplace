+-------------------------------------------+-----------------+
| Address                                   | uSTX            |
+-------------------------------------------+-----------------+
| ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM | 100000000000000 | /owner/super admin
+-------------------------------------------+-----------------+
| ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 | 100000000000000 | /doctor admin
+-------------------------------------------+-----------------+
| ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG | 100000000000000 | /user 1
+-------------------------------------------+-----------------+
| ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC | 100000000000000 | /user 2
+-------------------------------------------+-----------------+
| ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND  | 100000000000000 | /doctor 1
+-------------------------------------------+-----------------+
| ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB | 100000000000000 | /doctor 2
+-------------------------------------------+-----------------+
| ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0 | 100000000000000 |
+-------------------------------------------+-----------------+
| ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP | 100000000000000 |
+-------------------------------------------+-----------------+
| ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ | 100000000000000 |
+-------------------------------------------+-----------------+
| STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6  | 100000000000000 |
+-------------------------------------------+-----------------+

Set the transaction sender to an admin for initial setups
>> ::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
tx-sender switched to ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

Add a super-admin
>> (contract-call? .admin add-super-admin 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(ok true)

Add a regular admin with a role (assuming 'doctor-admin')
>> (contract-call? .admin add-admin 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 u"doctor-admin")
(ok true)

Remove an admin
>> (contract-call? .admin remove-admin 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
(ok true)

Add a regular admin again
>> (contract-call? .admin add-admin 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 u"doctor-admin")
(ok true)

Log an admin action
>> (contract-call? .audit-logs log-admin-action u"Added admin" u"Details here")
(ok true)

Fetch all log entries
>> (contract-call? .audit-logs get-audit-logs)
(ok ((tuple (action u"Add admin") (admin ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM) (details u"Added admin with role: doctor-admin") (timestamp u2)) (tuple (action u"Added admin") (admin ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM) (details u"Details here") (timestamp u2))))

>> (contract-call? .medtoken mint-for-marketplace u1000000)
Events emitted
{"type":"ft_mint_event","ft_mint_event":{"asset_identifier":"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.medtoken::MEDtoken","recipient":"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM","amount":"1000000"}}

>> (contract-call? .medtoken get-total-supply)
(ok u1000000)

Distribute tokens (only super admin/doctor admin can distribute to reward doctors and users for activities)
>> (contract-call? .admin distribute-tokens 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 u2)
Events emitted
{"type":"ft_transfer_event","ft_transfer_event":{"asset_identifier":"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.medtoken::MEDtoken","sender":"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM","recipient":"ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5","amount":"2"}}
(ok true)

Set activity price (only admin)
>> (contract-call? .activity-prices set-activity-price "consultation" u1000000 u500000)
(ok true)

>> (contract-call? .activity-prices get-activity "consultation")
(ok (tuple (doctor-payout u500000) (price u1000000)))

User registration
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
tx-sender switched to ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG

>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.user-profile register-user u"Alice" u"alice@example.com")
Events emitted
{"type":"contract_event","contract_event":{"contract_identifier":"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.user-profile","topic":"print","value":"{ email: u\"alice@example.com\", event: \"User registration\", name: u\"Alice\", user: 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG }"}}
(ok "User registered successfully, awaiting approval")

;; Update user profile
>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.user-profile update-user-profile u"Alice Updated" u"alice@example.com")
(err "USER_NOT_APPROVED")

;; Approve user (only admin)
>> ::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
tx-sender switched to ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
>> (contract-call? .user-profile approve-user 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
(ok "User approved")

Testing Reject User
>> ::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
tx-sender switched to ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.user-profile register-user u"Tim" u"tim@example.com")
Events emitted
{"type":"contract_event","contract_event":{"contract_identifier":"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.user-profile","topic":"print","value":"{ email: u\"tim@example.com\", event: \"User registration\", name: u\"Tim\", user: 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC }"}}
(ok "User registered successfully, awaiting approval")
;; Reject user (only admin)
>> ::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
tx-sender switched to ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
>> (contract-call? .user-profile reject-user 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
(ok "User rejected")

is user approved
>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.user-profile is-user-approved 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
(ok true)

Doctor registration
>> ::set_tx_sender ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
tx-sender switched to ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.doctor-profile register-doctor u"Dr. Bob" u"Cardiology")
(ok "Doctor registered successfully. Awaiting admin approval.")

;; Approve doctor (only admin)
>> ::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
tx-sender switched to ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
>> (contract-call? .doctor-profile approve-doctor 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND true)
(ok "Doctor approved and registered")

;; Update doctor profile
>> ::set_tx_sender ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
tx-sender switched to ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.doctor-profile update-doctor-profile u"Dr. Bob Updated" u"Cardiology")
(ok "Doctor profile updated successfully")

;; Suspend doctor (only admin)
>> ::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
tx-sender switched to ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
>> (contract-call? .doctor-profile suspend-doctor 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)
(ok "Doctor profile suspended successfully")

;; Remove doctor (only admin)
>> (contract-call? .doctor-profile remove-doctor 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)
(ok "Doctor removed")
>> (contract-call? .doctor-profile remove-doctor 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)
(err "DOCTOR_NOT_FOUND")

Book an appointment (user only)
>> ::set_tx_sender ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
tx-sender switched to ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.doctor-profile register-doctor u"Dr. Bob" u"Cardiology")
(ok "Doctor registered successfully. Awaiting admin approval.")

>> ::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
tx-sender switched to ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .doctor-profile approve-doctor 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND true)
(ok "Doctor approved and registered")

>> ::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
tx-sender switched to ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.appointments book-appointment 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND u1640995200)

>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.appointments book-appointment 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND u1640995200)
Events emitted
{"type":"stx_transfer_event","stx_transfer_event":{"sender":"ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG","recipient":"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM","amount":"1000000","memo":""}}
(ok u1)





;; Book an appointment
>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.appointments book-appointment 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND u1640995200)
Events emitted
{"type":"stx_transfer_event","stx_transfer_event":{"sender":"ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG","recipient":"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM","amount":"1000000","memo":""}}
(ok u1)


;; Cancel an appointment
>> (contract-call? .appointments cancel-appointment u1)

;; Get appointment details
>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.appointments get-appointment u1)

(ok (some (tuple (doctor ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND) (time u1640995200) (user ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG))))

;; Recommend a drug during an appointment (doctor)
>> ::set_tx_sender ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
tx-sender switched to ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.drug-recommendation recommend-drug 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG u"Aspirin")
(ok u1)


;; Complete an appointment
>> ::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.appointments complete-appointment u1)

Fetch log entry (assuming log-id is 1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.admin fetch-log u1)
;; Recommend a drug during an appointment

>> (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.drug-recommendation recommend-drug 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG u"Aspirin")
(ok u1)

