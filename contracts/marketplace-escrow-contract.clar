;; Decentralized Marketplace Escrow Contract
;; Enables secure peer-to-peer transactions with escrow functionality

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-invalid-status (err u105))
(define-constant err-self-transaction (err u106))
(define-constant err-empty-reason (err u107))
(define-constant err-invalid-winner (err u108))

(define-data-var next-order-id uint u1)

(define-map orders
  { order-id: uint }
  {
    buyer: principal,
    seller: principal,
    amount: uint,
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map order-disputes
  { order-id: uint }
  {
    disputed-by: principal,
    reason: (string-ascii 100),
    disputed-at: uint
  }
)

;; Private function to validate order exists
(define-private (validate-order-exists (order-id uint))
  (is-some (map-get? orders { order-id: order-id }))
)

;; Private function to validate reason is not empty
(define-private (validate-reason (reason (string-ascii 100)))
  (> (len reason) u0)
)

(define-public (create-order (seller principal) (amount uint))
  (let
    (
      (order-id (var-get next-order-id))
      (validated-seller seller)
      (validated-amount amount)
    )
    (asserts! (> validated-amount u0) err-invalid-amount)
    (asserts! (not (is-eq tx-sender validated-seller)) err-self-transaction)
    (try! (stx-transfer? validated-amount tx-sender (as-contract tx-sender)))
    (map-set orders
      { order-id: order-id }
      {
        buyer: tx-sender,
        seller: validated-seller,
        amount: validated-amount,
        status: "pending",
        created-at: burn-block-height
      }
    )
    (var-set next-order-id (+ order-id u1))
    (ok order-id)
  )
)

(define-public (complete-order (order-id uint))
  (let
    (
      (validated-order-id order-id)
      (order (unwrap! (map-get? orders { order-id: validated-order-id }) err-not-found))
    )
    (asserts! (validate-order-exists validated-order-id) err-not-found)
    (asserts! (is-eq tx-sender (get buyer order)) err-unauthorized)
    (asserts! (is-eq (get status order) "pending") err-invalid-status)
    (try! (as-contract (stx-transfer? (get amount order) tx-sender (get seller order))))
    (map-set orders
      { order-id: validated-order-id }
      (merge order { status: "completed" })
    )
    (ok true)
  )
)

(define-public (dispute-order (order-id uint) (reason (string-ascii 100)))
  (let
    (
      (validated-order-id order-id)
      (validated-reason reason)
      (order (unwrap! (map-get? orders { order-id: validated-order-id }) err-not-found))
    )
    (asserts! (validate-order-exists validated-order-id) err-not-found)
    (asserts! (validate-reason validated-reason) err-empty-reason)
    (asserts! (or (is-eq tx-sender (get buyer order)) (is-eq tx-sender (get seller order))) err-unauthorized)
    (asserts! (is-eq (get status order) "pending") err-invalid-status)
    (map-set order-disputes
      { order-id: validated-order-id }
      {
        disputed-by: tx-sender,
        reason: validated-reason,
        disputed-at: burn-block-height
      }
    )
    (map-set orders
      { order-id: validated-order-id }
      (merge order { status: "disputed" })
    )
    (ok true)
  )
)

(define-public (resolve-dispute (order-id uint) (winner principal))
  (let
    (
      (validated-order-id order-id)
      (validated-winner winner)
      (order (unwrap! (map-get? orders { order-id: validated-order-id }) err-not-found))
    )
    (asserts! (validate-order-exists validated-order-id) err-not-found)
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status order) "disputed") err-invalid-status)
    (asserts! (or (is-eq validated-winner (get buyer order)) (is-eq validated-winner (get seller order))) err-invalid-winner)
    (try! (as-contract (stx-transfer? (get amount order) tx-sender validated-winner)))
    (map-set orders
      { order-id: validated-order-id }
      (merge order { status: "resolved" })
    )
    (ok true)
  )
)

(define-read-only (get-order (order-id uint))
  (map-get? orders { order-id: order-id })
)

(define-read-only (get-dispute (order-id uint))
  (map-get? order-disputes { order-id: order-id })
)

(define-read-only (get-next-order-id)
  (var-get next-order-id)
)