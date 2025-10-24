(define-fungible-token data-access-token)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_SENSOR_NOT_FOUND (err u404))
(define-constant ERR_INSUFFICIENT_FUNDS (err u400))
(define-constant ERR_INVALID_SIGNATURE (err u403))
(define-constant ERR_DATA_EXPIRED (err u410))
(define-constant ERR_ACCESS_EXPIRED (err u411))
(define-constant ERR_SENSOR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_PRICE (err u402))
(define-constant ERR_NO_ACCESS (err u412))
(define-constant ERR_ALREADY_RATED (err u413))
(define-constant ERR_INVALID_RATING (err u414))

(define-data-var next-sensor-id uint u1)
(define-data-var platform-fee-rate uint u250)

(define-map sensors
  { sensor-id: uint }
  {
    owner: principal,
    location: (string-ascii 50),
    sensor-type: (string-ascii 30),
    price-per-hour: uint,
    public-key: (buff 33),
    active: bool,
    total-earned: uint,
    created-at: uint
  }
)

(define-map sensor-data
  { sensor-id: uint, timestamp: uint }
  {
    data-hash: (buff 32),
    signature: (buff 65),
    data-size: uint,
    verified: bool
  }
)

(define-map access-rights
  { buyer: principal, sensor-id: uint }
  {
    expires-at: uint,
    purchased-at: uint,
    amount-paid: uint
  }
)

(define-map sensor-owners
  { owner: principal }
  { sensor-count: uint }
)

(define-map buyer-stats
  { buyer: principal }
  {
    total-spent: uint,
    active-subscriptions: uint
  }
)

(define-map sensor-reputation
  { sensor-id: uint }
  {
    total-ratings: uint,
    total-score: uint,
    average-rating: uint,
    uptime-percentage: uint,
    total-data-published: uint
  }
)

(define-map buyer-ratings
  { buyer: principal, sensor-id: uint }
  {
    rating: uint,
    rated-at: uint
  }
)

(define-public (register-sensor (location (string-ascii 50)) (sensor-type (string-ascii 30)) (price-per-hour uint) (public-key (buff 33)))
  (let
    (
      (sensor-id (var-get next-sensor-id))
      (current-block burn-block-height)
    )
    (asserts! (> price-per-hour u0) ERR_INVALID_PRICE)
    (asserts! (is-eq (len public-key) u33) ERR_INVALID_SIGNATURE)
    
    (map-set sensors
      { sensor-id: sensor-id }
      {
        owner: tx-sender,
        location: location,
        sensor-type: sensor-type,
        price-per-hour: price-per-hour,
        public-key: public-key,
        active: true,
        total-earned: u0,
        created-at: current-block
      }
    )
    
    (map-set sensor-owners
      { owner: tx-sender }
      {
        sensor-count: (+ (get sensor-count (default-to { sensor-count: u0 } (map-get? sensor-owners { owner: tx-sender }))) u1)
      }
    )
    
    (map-set sensor-reputation
      { sensor-id: sensor-id }
      {
        total-ratings: u0,
        total-score: u0,
        average-rating: u0,
        uptime-percentage: u100,
        total-data-published: u0
      }
    )
    
    (var-set next-sensor-id (+ sensor-id u1))
    (ok sensor-id)
  )
)

(define-public (publish-data (sensor-id uint) (data-hash (buff 32)) (signature (buff 65)) (data-size uint))
  (let
    (
      (sensor (unwrap! (map-get? sensors { sensor-id: sensor-id }) ERR_SENSOR_NOT_FOUND))
      (current-block burn-block-height)
    )
    (asserts! (is-eq tx-sender (get owner sensor)) ERR_NOT_AUTHORIZED)
    (asserts! (get active sensor) ERR_SENSOR_NOT_FOUND)
    (asserts! (> data-size u0) ERR_INVALID_SIGNATURE)
    
    (map-set sensor-data
      { sensor-id: sensor-id, timestamp: current-block }
      {
        data-hash: data-hash,
        signature: signature,
        data-size: data-size,
        verified: true
      }
    )
    
    (let
      (
        (reputation (default-to { total-ratings: u0, total-score: u0, average-rating: u0, uptime-percentage: u100, total-data-published: u0 } (map-get? sensor-reputation { sensor-id: sensor-id })))
      )
      (map-set sensor-reputation
        { sensor-id: sensor-id }
        (merge reputation { total-data-published: (+ (get total-data-published reputation) u1) })
      )
    )
    
    (ok true)
  )
)

(define-public (purchase-access (sensor-id uint) (duration-hours uint))
  (let
    (
      (sensor (unwrap! (map-get? sensors { sensor-id: sensor-id }) ERR_SENSOR_NOT_FOUND))
      (total-cost (* (get price-per-hour sensor) duration-hours))
      (platform-fee (/ (* total-cost (var-get platform-fee-rate)) u10000))
      (seller-amount (- total-cost platform-fee))
      (current-block burn-block-height)
      (expires-at (+ current-block (* duration-hours u6)))
    )
    (asserts! (get active sensor) ERR_SENSOR_NOT_FOUND)
    (asserts! (> duration-hours u0) ERR_INVALID_PRICE)
    
    (try! (ft-transfer? data-access-token total-cost tx-sender CONTRACT_OWNER))
    (try! (ft-transfer? data-access-token seller-amount CONTRACT_OWNER (get owner sensor)))
    
    (map-set access-rights
      { buyer: tx-sender, sensor-id: sensor-id }
      {
        expires-at: expires-at,
        purchased-at: current-block,
        amount-paid: total-cost
      }
    )
    
    (map-set sensors
      { sensor-id: sensor-id }
      (merge sensor { total-earned: (+ (get total-earned sensor) seller-amount) })
    )
    
    (map-set buyer-stats
      { buyer: tx-sender }
      {
        total-spent: (+ total-cost (get total-spent (default-to { total-spent: u0, active-subscriptions: u0 } (map-get? buyer-stats { buyer: tx-sender })))),
        active-subscriptions: (+ u1 (get active-subscriptions (default-to { total-spent: u0, active-subscriptions: u0 } (map-get? buyer-stats { buyer: tx-sender }))))
      }
    )
    
    (ok expires-at)
  )
)

(define-public (update-sensor-price (sensor-id uint) (new-price uint))
  (let
    (
      (sensor (unwrap! (map-get? sensors { sensor-id: sensor-id }) ERR_SENSOR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get owner sensor)) ERR_NOT_AUTHORIZED)
    (asserts! (> new-price u0) ERR_INVALID_PRICE)
    
    (map-set sensors
      { sensor-id: sensor-id }
      (merge sensor { price-per-hour: new-price })
    )
    
    (ok true)
  )
)

(define-public (deactivate-sensor (sensor-id uint))
  (let
    (
      (sensor (unwrap! (map-get? sensors { sensor-id: sensor-id }) ERR_SENSOR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get owner sensor)) ERR_NOT_AUTHORIZED)
    
    (map-set sensors
      { sensor-id: sensor-id }
      (merge sensor { active: false })
    )
    
    (ok true)
  )
)

(define-public (mint-tokens (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (ft-mint? data-access-token amount recipient)
  )
)

(define-public (set-platform-fee (new-fee-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-fee-rate u1000) ERR_INVALID_PRICE)
    (var-set platform-fee-rate new-fee-rate)
    (ok true)
  )
)

(define-read-only (get-sensor (sensor-id uint))
  (map-get? sensors { sensor-id: sensor-id })
)

(define-read-only (get-sensor-data (sensor-id uint) (timestamp uint))
  (map-get? sensor-data { sensor-id: sensor-id, timestamp: timestamp })
)

(define-read-only (get-access-rights (buyer principal) (sensor-id uint))
  (map-get? access-rights { buyer: buyer, sensor-id: sensor-id })
)

(define-read-only (has-valid-access (buyer principal) (sensor-id uint))
  (let
    (
      (access (map-get? access-rights { buyer: buyer, sensor-id: sensor-id }))
      (current-block burn-block-height)
    )
    (match access
      rights (< current-block (get expires-at rights))
      false
    )
  )
)

(define-read-only (get-sensor-count)
  (- (var-get next-sensor-id) u1)
)

(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate)
)

(define-read-only (get-token-balance (account principal))
  (ft-get-balance data-access-token account)
)

(define-read-only (get-sensor-owner-stats (owner principal))
  (map-get? sensor-owners { owner: owner })
)

(define-read-only (get-buyer-stats (buyer principal))
  (map-get? buyer-stats { buyer: buyer })
)

(define-read-only (calculate-access-cost (sensor-id uint) (duration-hours uint))
  (let
    (
      (sensor (map-get? sensors { sensor-id: sensor-id }))
    )
    (match sensor
      s (* (get price-per-hour s) duration-hours)
      u0
    )
  )
)

(define-read-only (verify-data-signature (sensor-id uint) (data-hash (buff 32)) (signature (buff 65)))
  (let
    (
      (sensor (map-get? sensors { sensor-id: sensor-id }))
    )
    (match sensor
      s (secp256k1-verify data-hash signature (get public-key s))
      false
    )
  )
)

(define-public (rate-sensor (sensor-id uint) (rating uint))
  (let
    (
      (sensor (unwrap! (map-get? sensors { sensor-id: sensor-id }) ERR_SENSOR_NOT_FOUND))
      (access (unwrap! (map-get? access-rights { buyer: tx-sender, sensor-id: sensor-id }) ERR_NO_ACCESS))
      (existing-rating (map-get? buyer-ratings { buyer: tx-sender, sensor-id: sensor-id }))
      (reputation (default-to { total-ratings: u0, total-score: u0, average-rating: u0, uptime-percentage: u100, total-data-published: u0 } (map-get? sensor-reputation { sensor-id: sensor-id })))
      (current-block burn-block-height)
    )
    (asserts! (is-none existing-rating) ERR_ALREADY_RATED)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_RATING)
    (asserts! (< current-block (get expires-at access)) ERR_ACCESS_EXPIRED)
    
    (let
      (
        (new-total-ratings (+ (get total-ratings reputation) u1))
        (new-total-score (+ (get total-score reputation) rating))
        (new-average-rating (/ new-total-score new-total-ratings))
      )
      (map-set sensor-reputation
        { sensor-id: sensor-id }
        (merge reputation {
          total-ratings: new-total-ratings,
          total-score: new-total-score,
          average-rating: new-average-rating
        })
      )
    )
    
    (map-set buyer-ratings
      { buyer: tx-sender, sensor-id: sensor-id }
      {
        rating: rating,
        rated-at: current-block
      }
    )
    
    (ok true)
  )
)

(define-read-only (get-sensor-reputation (sensor-id uint))
  (map-get? sensor-reputation { sensor-id: sensor-id })
)

(define-read-only (get-buyer-rating (buyer principal) (sensor-id uint))
  (map-get? buyer-ratings { buyer: buyer, sensor-id: sensor-id })
)

(define-read-only (get-sensor-with-reputation (sensor-id uint))
  (let
    (
      (sensor (map-get? sensors { sensor-id: sensor-id }))
      (reputation (map-get? sensor-reputation { sensor-id: sensor-id }))
    )
    (match sensor
      s (some { sensor: s, reputation: reputation })
      none
    )
  )
)
