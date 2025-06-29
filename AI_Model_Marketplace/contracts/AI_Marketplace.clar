;; AI Model Marketplace - Decentralized ML Trading Hub
;; Addressing the $42.1B AI token market cap and rise of AI/ML integration
;; Marketplace for trading, licensing, and monetizing AI models on-chain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-model-exists (err u1200))
(define-constant err-invalid-model (err u1201))
(define-constant err-insufficient-payment (err u1202))
(define-constant err-not-authorized (err u1203))
(define-constant err-license-expired (err u1204))
(define-constant err-invalid-performance (err u1205))
(define-constant err-already-reviewed (err u1206))
(define-constant err-stake-locked (err u1207))

;; Marketplace parameters
(define-constant min-model-stake u50000000) ;; 50 STX minimum stake
(define-constant platform-fee u250) ;; 2.5% platform fee
(define-constant review-reward u1000000) ;; 1 STX per review
(define-constant performance-threshold u70) ;; 70% accuracy minimum

;; Data Variables
(define-data-var total-models uint u0)
(define-data-var total-licenses-sold uint u0)
(define-data-var platform-revenue uint u0)
(define-data-var top-model-id uint u0)

;; NFT for model ownership
(define-non-fungible-token ai-model-nft uint)

;; Maps
(define-map ai-models
    uint ;; model-id
    {
        creator: principal,
        name: (string-ascii 50),
        category: (string-ascii 20), ;; "nlp", "vision", "prediction", "generative"
        architecture: (string-ascii 30),
        parameters-count: uint,
        accuracy-score: uint,
        model-hash: (buff 32),
        dataset-hash: (buff 32),
        price-per-use: uint,
        total-uses: uint,
        stake-amount: uint,
        is-active: bool,
        creation-block: uint
    }
)

(define-map model-licenses
    {model-id: uint, licensee: principal}
    {
        license-type: (string-ascii 20), ;; "single", "subscription", "unlimited"
        uses-remaining: uint,
        expiry-block: uint,
        price-paid: uint,
        performance-rating: uint
    }
)

(define-map model-performance
    uint ;; model-id
    {
        total-inferences: uint,
        successful-predictions: uint,
        average-latency: uint,
        compute-cost: uint,
        user-ratings: uint,
        rating-count: uint
    }
)

(define-map inference-requests
    uint ;; request-id
    {
        model-id: uint,
        requester: principal,
        input-hash: (buff 32),
        output-hash: (buff 32),
        compute-units: uint,
        timestamp: uint,
        verified: bool
    }
)

(define-map model-reviews
    {model-id: uint, reviewer: principal}
    {
        accuracy-rating: uint,
        performance-rating: uint,
        documentation-rating: uint,
        review-text: (string-utf8 200),
        helpful-votes: uint
    }
)

;; Helper functions
(define-private (min (a uint) (b uint))
    (if (< a b) a b)
)

(define-private (max (a uint) (b uint))
    (if (> a b) a b)
)

;; Read-only functions
(define-read-only (get-model (model-id uint))
    (map-get? ai-models model-id)
)

(define-read-only (get-model-performance (model-id uint))
    (default-to 
        {total-inferences: u0, successful-predictions: u0, average-latency: u0, 
         compute-cost: u0, user-ratings: u0, rating-count: u0}
        (map-get? model-performance model-id))
)

(define-read-only (get-license (model-id uint) (licensee principal))
    (map-get? model-licenses {model-id: model-id, licensee: licensee})
)

(define-read-only (calculate-model-score (model-id uint))
    (let (
        (model (unwrap! (get-model model-id) u0))
        (performance (get-model-performance model-id))
    )
        (/ (+ (* (get accuracy-score model) u40)
              (* (get user-ratings performance) u30)
              (* (min u100 (/ (get total-uses model) u100)) u30))
           u100)
    )
)

;; Public functions

;; List new AI model
(define-public (list-model
    (name (string-ascii 50))
    (category (string-ascii 20))
    (architecture (string-ascii 30))
    (parameters-count uint)
    (accuracy-score uint)
    (model-hash (buff 32))
    (dataset-hash (buff 32))
    (price-per-use uint))
    (let (
        (model-id (+ (var-get total-models) u1))
    )
        (asserts! (>= accuracy-score performance-threshold) err-invalid-performance)
        (asserts! (> price-per-use u0) err-insufficient-payment)
        
        ;; Transfer stake
        (try! (stx-transfer? min-model-stake tx-sender (as-contract tx-sender)))
        
        ;; Mint NFT
        (try! (nft-mint? ai-model-nft model-id tx-sender))
        
        ;; Create model listing
        (map-set ai-models model-id {
            creator: tx-sender,
            name: name,
            category: category,
            architecture: architecture,
            parameters-count: parameters-count,
            accuracy-score: accuracy-score,
            model-hash: model-hash,
            dataset-hash: dataset-hash,
            price-per-use: price-per-use,
            total-uses: u0,
            stake-amount: min-model-stake,
            is-active: true,
            creation-block: stacks-block-height
        })
        
        ;; Initialize performance metrics
        (map-set model-performance model-id {
            total-inferences: u0,
            successful-predictions: u0,
            average-latency: u0,
            compute-cost: u0,
            user-ratings: u50,
            rating-count: u0
        })
        
        (var-set total-models model-id)
        
        (ok model-id)
    )
)

;; Purchase model license
(define-public (purchase-license
    (model-id uint)
    (license-type (string-ascii 20))
    (uses uint))
    (let (
        (model (unwrap! (get-model model-id) err-invalid-model))
        (base-price (get price-per-use model))
        (total-price (calculate-license-price base-price license-type uses))
    )
        (asserts! (get is-active model) err-invalid-model)
        
        ;; Transfer payment
        (let (
            (platform-cut (/ (* total-price platform-fee) u10000))
            (creator-payment (- total-price platform-cut))
        )
            (try! (stx-transfer? total-price tx-sender (as-contract tx-sender)))
            (try! (as-contract (stx-transfer? creator-payment tx-sender (get creator model))))
            
            (var-set platform-revenue (+ (var-get platform-revenue) platform-cut))
        )
        
        ;; Create license
        (map-set model-licenses {model-id: model-id, licensee: tx-sender} {
            license-type: license-type,
            uses-remaining: (if (is-eq license-type "unlimited") u999999999 uses),
            expiry-block: (if (is-eq license-type "subscription") 
                            (+ stacks-block-height u4320) ;; 30 days
                            u999999999),
            price-paid: total-price,
            performance-rating: u0
        })
        
        ;; Update model stats
        (map-set ai-models model-id (merge model {
            total-uses: (+ (get total-uses model) u1)
        }))
        
        (var-set total-licenses-sold (+ (var-get total-licenses-sold) u1))
        
        (ok true)
    )
)

;; Use model for inference
(define-public (request-inference
    (model-id uint)
    (input-hash (buff 32))
    (compute-units uint))
    (let (
        (model (unwrap! (get-model model-id) err-invalid-model))
        (license (unwrap! (get-license model-id tx-sender) err-not-authorized))
        (request-id (var-get total-licenses-sold))
    )
        (asserts! (get is-active model) err-invalid-model)
        (asserts! (> (get uses-remaining license) u0) err-license-expired)
        (asserts! (< stacks-block-height (get expiry-block license)) err-license-expired)
        
        ;; Create inference request
        (map-set inference-requests request-id {
            model-id: model-id,
            requester: tx-sender,
            input-hash: input-hash,
            output-hash: 0x00,
            compute-units: compute-units,
            timestamp: stacks-block-height,
            verified: false
        })
        
        ;; Update license uses
        (map-set model-licenses {model-id: model-id, licensee: tx-sender}
            (merge license {
                uses-remaining: (- (get uses-remaining license) u1)
            }))
        
        ;; Update performance metrics
        (let (
            (performance (get-model-performance model-id))
        )
            (map-set model-performance model-id (merge performance {
                total-inferences: (+ (get total-inferences performance) u1),
                compute-cost: (+ (get compute-cost performance) compute-units)
            }))
        )
        
        (ok request-id)
    )
)

;; Submit model review
(define-public (review-model
    (model-id uint)
    (accuracy-rating uint)
    (performance-rating uint)
    (documentation-rating uint)
    (review-text (string-utf8 200)))
    (let (
        (model (unwrap! (get-model model-id) err-invalid-model))
        (existing-review (map-get? model-reviews {model-id: model-id, reviewer: tx-sender}))
    )
        (asserts! (is-none existing-review) err-already-reviewed)
        (asserts! (and (<= accuracy-rating u100) (<= performance-rating u100) 
                      (<= documentation-rating u100)) err-invalid-performance)
        
        ;; Must have used the model to review
        (asserts! (is-some (get-license model-id tx-sender)) err-not-authorized)
        
        ;; Create review
        (map-set model-reviews {model-id: model-id, reviewer: tx-sender} {
            accuracy-rating: accuracy-rating,
            performance-rating: performance-rating,
            documentation-rating: documentation-rating,
            review-text: review-text,
            helpful-votes: u0
        })
        
        ;; Update model ratings
        (let (
            (performance (get-model-performance model-id))
            (new-rating (/ (+ accuracy-rating performance-rating documentation-rating) u3))
            (current-avg (get user-ratings performance))
            (current-count (get rating-count performance))
        )
            (map-set model-performance model-id (merge performance {
                user-ratings: (/ (+ (* current-avg current-count) new-rating) 
                                (+ current-count u1)),
                rating-count: (+ current-count u1)
            }))
        )
        
        ;; Reward reviewer
        (try! (as-contract (stx-transfer? review-reward tx-sender tx-sender)))
        
        (ok true)
    )
)

;; Update model (by creator)
(define-public (update-model
    (model-id uint)
    (new-model-hash (buff 32))
    (new-accuracy uint))
    (let (
        (model (unwrap! (get-model model-id) err-invalid-model))
    )
        (asserts! (is-eq (get creator model) tx-sender) err-not-authorized)
        (asserts! (>= new-accuracy (get accuracy-score model)) err-invalid-performance)
        
        (map-set ai-models model-id (merge model {
            model-hash: new-model-hash,
            accuracy-score: new-accuracy
        }))
        
        (ok true)
    )
)

;; Challenge model performance
(define-public (challenge-model
    (model-id uint)
    (evidence-hash (buff 32)))
    (let (
        (model (unwrap! (get-model model-id) err-invalid-model))
        (challenger-stake u10000000) ;; 10 STX
    )
        ;; Transfer challenge stake
        (try! (stx-transfer? challenger-stake tx-sender (as-contract tx-sender)))
        
        ;; In production, this would trigger verification process
        ;; For now, we'll just record the challenge
        
        (ok true)
    )
)

;; Private functions
(define-private (calculate-license-price (base-price uint) (license-type (string-ascii 20)) (uses uint))
    (if (is-eq license-type "single")
        base-price
        (if (is-eq license-type "subscription")
            (* base-price u100) ;; 100x for monthly
            (* base-price u1000))) ;; 1000x for unlimited
)

;; Update top model
(define-private (update-top-model)
    (let (
        (current-top (var-get top-model-id))
        ;; In production, would iterate through all models
    )
        true
    )
)