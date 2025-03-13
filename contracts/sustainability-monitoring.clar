;; Sustainability Monitoring Contract
;; Tracks fish populations and adjusts quotas

(define-data-var counter uint u0)

(define-map population-data
  { id: uint }
  {
    species-id: uint,
    region: (string-ascii 32),
    population: uint,
    timestamp: uint,
    sustainable-yield: uint
  }
)

(define-map researchers
  { address: principal }
  { active: bool }
)

(define-map quota-adjustments
  { species-id: uint, region: (string-ascii 32) }
  {
    adjustment-percentage: int,
    reason: (string-ascii 256),
    timestamp: uint
  }
)

;; Initialize contract with first researcher
(define-public (initialize)
  (begin
    (map-set researchers { address: tx-sender } { active: true })
    (ok true)
  )
)

;; Record population data
(define-public (record-population
                (species-id uint)
                (region (string-ascii 32))
                (population uint)
                (sustainable-yield uint))
  (let ((new-id (+ (var-get counter) u1)))

    ;; Only researchers can record population data
    (asserts! (is-researcher tx-sender) (err u1))

    ;; Update counter
    (var-set counter new-id)

    ;; Store population data
    (map-set population-data
      { id: new-id }
      {
        species-id: species-id,
        region: region,
        population: population,
        timestamp: block-height,
        sustainable-yield: sustainable-yield
      }
    )

    (ok new-id)
  )
)

;; Recommend quota adjustment
(define-public (recommend-adjustment
                (species-id uint)
                (region (string-ascii 32))
                (adjustment-percentage int)
                (reason (string-ascii 256)))
  (begin
    ;; Only researchers can recommend adjustments
    (asserts! (is-researcher tx-sender) (err u1))

    ;; Store adjustment recommendation
    (map-set quota-adjustments
      { species-id: species-id, region: region }
      {
        adjustment-percentage: adjustment-percentage,
        reason: reason,
        timestamp: block-height
      }
    )

    (ok true)
  )
)

;; Add a researcher
(define-public (add-researcher (address principal))
  (begin
    ;; Only researchers can add researchers
    (asserts! (is-researcher tx-sender) (err u1))

    (map-set researchers
      { address: address }
      { active: true }
    )

    (ok true)
  )
)

;; Get population data
(define-read-only (get-population-data (data-id uint))
  (map-get? population-data { id: data-id })
)

;; Get quota adjustment
(define-read-only (get-quota-adjustment (species-id uint) (region (string-ascii 32)))
  (map-get? quota-adjustments { species-id: species-id, region: region })
)

;; Check if address is researcher
(define-read-only (is-researcher (address principal))
  (default-to false (get active (map-get? researchers { address: address })))
)

