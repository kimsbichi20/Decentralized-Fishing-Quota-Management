;; Quota Allocation Contract
;; Assigns fishing rights to vessels or companies

(define-data-var counter uint u0)

(define-map vessels
  { id: uint }
  {
    name: (string-ascii 64),
    owner: principal,
    active: bool
  }
)

(define-map quotas
  { vessel-id: uint, species-id: uint }
  {
    amount: uint,
    region: (string-ascii 32),
    season-start: uint,
    season-end: uint,
    active: bool
  }
)

(define-map species
  { id: uint }
  {
    name: (string-ascii 64),
    active: bool
  }
)

(define-map admins
  { address: principal }
  { active: bool }
)

;; Initialize contract with first admin
(define-public (initialize)
  (begin
    (map-set admins { address: tx-sender } { active: true })
    (ok true)
  )
)

;; Register a new vessel
(define-public (register-vessel
                (name (string-ascii 64)))
  (let ((new-id (+ (var-get counter) u1)))
    ;; Update counter
    (var-set counter new-id)

    ;; Store vessel data
    (map-set vessels
      { id: new-id }
      {
        name: name,
        owner: tx-sender,
        active: true
      }
    )

    (ok new-id)
  )
)

;; Register a new species
(define-public (register-species
                (id uint)
                (name (string-ascii 64)))
  (begin
    ;; Only admins can register species
    (asserts! (is-admin tx-sender) (err u1))

    ;; Store species data
    (map-set species
      { id: id }
      {
        name: name,
        active: true
      }
    )

    (ok true)
  )
)

;; Allocate quota to a vessel
(define-public (allocate-quota
                (vessel-id uint)
                (species-id uint)
                (amount uint)
                (region (string-ascii 32))
                (season-start uint)
                (season-end uint))
  (begin
    ;; Only admins can allocate quotas
    (asserts! (is-admin tx-sender) (err u1))

    ;; Vessel and species must exist
    (asserts! (and
                (is-some (map-get? vessels { id: vessel-id }))
                (is-some (map-get? species { id: species-id })))
              (err u2))

    ;; Store quota data
    (map-set quotas
      { vessel-id: vessel-id, species-id: species-id }
      {
        amount: amount,
        region: region,
        season-start: season-start,
        season-end: season-end,
        active: true
      }
    )

    (ok true)
  )
)

;; Update quota amount
(define-public (update-quota
                (vessel-id uint)
                (species-id uint)
                (new-amount uint))
  (let ((quota (map-get? quotas { vessel-id: vessel-id, species-id: species-id })))

    ;; Only admins can update quotas
    (asserts! (is-admin tx-sender) (err u1))

    ;; Quota must exist
    (asserts! (is-some quota) (err u2))

    ;; Store updated quota
    (map-set quotas
      { vessel-id: vessel-id, species-id: species-id }
      (merge (unwrap-panic quota) { amount: new-amount })
    )

    (ok true)
  )
)

;; Add an admin
(define-public (add-admin (address principal))
  (begin
    ;; Only admins can add admins
    (asserts! (is-admin tx-sender) (err u1))

    (map-set admins
      { address: address }
      { active: true }
    )

    (ok true)
  )
)

;; Get vessel details
(define-read-only (get-vessel (vessel-id uint))
  (map-get? vessels { id: vessel-id })
)

;; Get quota details
(define-read-only (get-quota (vessel-id uint) (species-id uint))
  (map-get? quotas { vessel-id: vessel-id, species-id: species-id })
)

;; Get species details
(define-read-only (get-species (species-id uint))
  (map-get? species { id: species-id })
)

;; Check if address is admin
(define-read-only (is-admin (address principal))
  (default-to false (get active (map-get? admins { address: address })))
)

