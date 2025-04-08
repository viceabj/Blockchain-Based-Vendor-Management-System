;; Qualification Verification Contract
;; Validates capabilities and certifications

;; Define data maps for storing qualification information
(define-map qualifications
  { supplier-id: uint, qualification-id: uint }
  {
    certification-type: (string-utf8 100),
    issuer: (string-utf8 100),
    issue-date: uint,
    expiry-date: uint,
    verified: bool
  }
)

;; Keep track of qualification count per supplier
(define-map qualification-counts
  { supplier-id: uint }
  { count: uint }
)

;; Add a new qualification for a supplier
(define-public (add-qualification
                (supplier-id uint)
                (certification-type (string-utf8 100))
                (issuer (string-utf8 100))
                (issue-date uint)
                (expiry-date uint))
  (let (
    (current-count (default-to { count: u0 } (map-get? qualification-counts { supplier-id: supplier-id })))
    (new-id (+ (get count current-count) u1))
  )
    (begin
      (map-set qualifications
        { supplier-id: supplier-id, qualification-id: new-id }
        {
          certification-type: certification-type,
          issuer: issuer,
          issue-date: issue-date,
          expiry-date: expiry-date,
          verified: false
        }
      )
      (map-set qualification-counts
        { supplier-id: supplier-id }
        { count: new-id }
      )
      (ok new-id)
    )
  )
)

;; Verify a qualification
(define-public (verify-qualification (supplier-id uint) (qualification-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (match (map-get? qualifications { supplier-id: supplier-id, qualification-id: qualification-id })
      qualification (begin
        (map-set qualifications
          { supplier-id: supplier-id, qualification-id: qualification-id }
          (merge qualification { verified: true })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Get qualification details
(define-read-only (get-qualification (supplier-id uint) (qualification-id uint))
  (map-get? qualifications { supplier-id: supplier-id, qualification-id: qualification-id })
)

;; Check if a qualification is valid (not expired and verified)
(define-read-only (is-qualification-valid (supplier-id uint) (qualification-id uint))
  (match (map-get? qualifications { supplier-id: supplier-id, qualification-id: qualification-id })
    qualification (and
                    (get verified qualification)
                    (< block-height (get expiry-date qualification)))
    false
  )
)

;; Contract owner
(define-constant contract-owner tx-sender)
