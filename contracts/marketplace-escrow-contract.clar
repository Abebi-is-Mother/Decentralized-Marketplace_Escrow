;; Decentralized Marketplace Escrow Contract
;; Enables secure peer-to-peer transactions with escrow functionality

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-invalid-status (err u105))

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

(define-public (create-order (seller principal) (amount uint))
  (let
    (
      (order-id (var-get next-order-id))
    )
    (asserts! (> amount u0) err-invalid-amount)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set orders
      { order-id: order-id }
      {
        buyer: tx-sender,
        seller: seller,
        amount: amount,
        status: "pending",
        created-at: block-height
      }
    )
    (var-set next-order-id (+ order-id u1))
    (ok order-id)
  )
)

(define-public (complete-order (order-id uint))
  (let
    (
      (order (unwrap! (map-get? orders { order-id: order-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get buyer order)) err-unauthorized)
    (asserts! (is-eq (get status order) "pending") err-invalid-status)
    (try! (as-contract (stx-transfer? (get amount order) tx-sender (get seller order))))
    (map-set orders
      { order-id: order-id }
      (merge order { status: "completed" })
    )
    (ok true)
  )
)

(define-public (dispute-order (order-id uint) (reason (string-ascii 100)))
  (let
    (
      (order (unwrap! (map-get? orders { order-id: order-id }) err-not-found))
    )
    (asserts! (or (is-eq tx-sender (get buyer order)) (is-eq tx-sender (get seller order))) err-unauthorized)
    (asserts! (is-eq (get status order) "pending") err-invalid-status)
    (map-set order-disputes
      { order-id: order-id }
      {
        disputed-by: tx-sender,
        reason: reason,
        disputed-at: block-height
      }
    )
    (map-set orders
      { order-id: order-id }
      (merge order { status: "disputed" })
    )
    (ok true)
  )
)

(define-public (resolve-dispute (order-id uint) (winner principal))
  (let
    (
      (order (unwrap! (map-get? orders { order-id: order-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status order) "disputed") err-invalid-status)
    (try! (as-contract (stx-transfer? (get amount order) tx-sender winner)))
    (map-set orders
      { order-id: order-id }
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