;; ProofYou - Trustless Digital Identity Authentication and Access Layer Control

(define-constant ADMIN tx-sender)

;; Error Codes
(define-constant ERR_UNAUTH (err u100))
(define-constant ERR_VAL_EXISTS (err u101))
(define-constant ERR_INVALID_VAL (err u102))
(define-constant ERR_ID_VALIDATED (err u103))
(define-constant ERR_ID_NOT_VAL (err u104))
(define-constant ERR_INVALID_TIER (err u105))
(define-constant ERR_NOT_ADMIN (err u106))
(define-constant ERR_INVALID_HASH (err u107))

;; Storage Maps
(define-map val-registry principal bool)
(define-map id-verifs 
  { usr: principal } 
  { 
    verified: bool, 
    tier: uint, 
    verified-at: uint, 
    hash: (buff 32),
    verified-by: principal 
  }
)

;; Read-only Utilities

(define-read-only (check-val (id principal))
  (default-to false (get-val-status id))
)

(define-read-only (get-val-status (id principal))
  (map-get? val-registry id)
)

(define-read-only (is-usr-verified (u principal))
  (default-to false (get verified (get-usr-record u)))
)

(define-read-only (get-usr-record (u principal))
  (map-get? id-verifs { usr: u })
)

(define-read-only (get-usr-tier (u principal))
  (default-to u0 (get tier (get-usr-record u)))
)

;; Private Validations

(define-private (is-valid-tier (t uint))
  (or (is-eq t u1) (is-eq t u2) (is-eq t u3))
)

(define-private (is-nonzero-hash (h (buff 32)))
  (not (is-eq h 0x0000000000000000000000000000000000000000000000000000000000000000))
)

;; Public Functions

(define-public (add-val (v principal))
  (begin
    (asserts! (is-eq tx-sender ADMIN) ERR_UNAUTH)
    (asserts! (not (check-val v)) ERR_VAL_EXISTS)
    (ok (map-set val-registry v true))
  )
)

(define-public (remove-val (v principal))
  (begin
    (asserts! (is-eq tx-sender ADMIN) ERR_UNAUTH)
    (asserts! (check-val v) ERR_INVALID_VAL)
    (ok (map-set val-registry v false))
  )
)

(define-public (verify-id (u principal) (t uint) (h (buff 32)))
  (begin
    (asserts! (check-val tx-sender) ERR_UNAUTH)
    (asserts! (is-valid-tier t) ERR_INVALID_TIER)
    (asserts! (is-nonzero-hash h) ERR_INVALID_HASH)

    (let ((usr-key { usr: u })
          (verif-data { 
            verified: true, 
            tier: t, 
            verified-at: stacks-block-height, 
            hash: h,
            verified-by: tx-sender 
          }))
      (ok (map-set id-verifs usr-key verif-data))
    )
  )
)

(define-public (revoke-id (u principal))
  (let ((rec (unwrap! (get-usr-record u) ERR_ID_NOT_VAL))
        (usr-key { usr: u })
        (revoked-data { 
          verified: false, 
          tier: u0, 
          verified-at: stacks-block-height, 
          hash: 0x0000000000000000000000000000000000000000000000000000000000000000,
          verified-by: tx-sender 
        }))
    (begin
      (asserts! (or 
                 (is-eq tx-sender (get verified-by rec))
                 (is-eq tx-sender ADMIN)) 
                ERR_UNAUTH)
      (ok (map-set id-verifs usr-key revoked-data))
    )
  )
)

(define-public (self-revoke)
  (let ((usr tx-sender)
        (usr-key { usr: tx-sender })
        (revoked-data { 
          verified: false, 
          tier: u0, 
          verified-at: stacks-block-height, 
          hash: 0x0000000000000000000000000000000000000000000000000000000000000000,
          verified-by: tx-sender 
        }))
    (begin
      (asserts! (is-usr-verified usr) ERR_ID_NOT_VAL)
      (ok (map-set id-verifs usr-key revoked-data))
    )
  )
)