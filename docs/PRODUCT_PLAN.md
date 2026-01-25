# Ledgoria - Product Plan

## Vision

A modern Applicant Tracking System that prioritizes compliance-first design, candidate experience, and integration with trust/verification workflows. Positioned to compete with Greenhouse, Lever, and iCIMS while differentiating through identity verification and defensible hiring decisions.

---

## Phase 1: Foundation (MVP) - COMPLETE

Goal: Core hiring workflow that can track candidates through a pipeline.

**Status: DELIVERED** - 325 points, 431 tests passing

### 1.1 Job Requisitions
- [x] Job model: title, description, location, employment_type, department
- [x] Hiring manager assignment
- [x] Requisition status: `draft` → `pending_approval` → `open` → `on_hold` → `closed`
- [x] Approval workflow with JobApproval model

### 1.2 Candidate Profiles
- [x] Candidate model: name, email, phone, source, resume attachment
- [x] Source tracking: career_site, job_board, referral, agency, linkedin, direct
- [x] Resume file upload (Active Storage)
- [x] PII encryption for sensitive fields (SSN)
- [x] Duplicate detection (email match per organization)

### 1.3 Applications & Pipeline
- [x] Application model linking Candidate ↔ Job
- [x] Configurable stages per organization
- [x] 8-state workflow: new → screening → interviewing → assessment → background_check → offered → hired/rejected/withdrawn
- [x] Stage transitions with timestamps and audit trail
- [x] Kanban pipeline view with drag-drop
- [x] Rating and starring for candidates

### 1.4 User & Access
- [x] User model with Devise authentication
- [x] Roles: admin, recruiter, hiring_manager (extensible)
- [x] Full RBAC with Pundit policies
- [x] Admin UI for user and role management
- [x] Reference data management with i18n

### 1.5 Audit Foundation
- [x] Immutable AuditLog model for all changes
- [x] Auditable concern for automatic change tracking
- [x] Decision tracking (rejection reasons)
- [x] SLA alerts for stuck candidates

### 1.6 Career Site & Application Flow
- [x] Public job listings with search and filters
- [x] Job detail pages with apply button
- [x] Frictionless apply (no account required)
- [x] Resume upload
- [x] Tokenized status tracking
- [x] Email notifications (confirmation, status updates)

### 1.7 Dashboard
- [x] Recruiter dashboard with task queue
- [x] Pipeline summary
- [x] Activity feed
- [x] Quick links

**Deliverable:** Recruiters can post jobs, receive applications, move candidates through stages, and make hiring decisions with an audit trail. Candidates can browse jobs, apply without an account, and track their application status.

---

## Phase 2: Scheduling & Evaluation - COMPLETE

Goal: Structured interview process with feedback collection.

**Status: DELIVERED** - 636 tests passing (205 new)

### 2.1 Interview Scheduling
- [x] Interview model: candidate, job, interviewer(s), datetime, type
- [x] Interview types: phone_screen, onsite, video, panel
- [x] Interview state machine: scheduled → confirmed → completed/cancelled/no_show
- [x] InterviewParticipant model for interviewer assignments
- [x] CalendarIntegration model for Google/Outlook sync
- [x] Email notifications to candidates and interviewers

### 2.2 Scorecards & Feedback
- [x] ScorecardTemplate with sections and items
- [x] Competency-based ratings (1-5 scale)
- [x] ScorecardResponse model for interviewer feedback
- [x] Visibility rules (hide feedback until submitted)
- [x] Scorecard state machine: draft → submitted → locked

### 2.3 Interview Kits & Decisions
- [x] QuestionBank model for reusable questions
- [x] InterviewKit linking questions to interviews
- [x] HiringDecision model (immutable: hire/reject/hold)
- [x] Decision approval workflow with HiringDecisionApproval
- [x] Interviewer preparation view

**Deliverable:** Full interview loop with structured evaluation and bias-resistant feedback collection.

---

## Phase 3: Enhanced Candidate Experience - COMPLETE

Goal: Advanced candidate portal and self-service features.

**Status: DELIVERED** - 699 tests passing (63 new)

### 3.1 Career Site Enhancements
- [x] Public job listings (filterable) - Done in Phase 1
- [x] OrganizationBranding model (logo, colors, custom CSS)
- [x] SEO-friendly job pages
- [x] Mobile-responsive design - Done in Phase 1

### 3.2 Advanced Application Flow
- [x] Frictionless apply (no account required) - Done in Phase 1
- [x] ApplicationQuestion model for custom questions per job
- [x] ApplicationQuestionResponse for candidate answers
- [x] Application confirmation emails - Done in Phase 1

### 3.3 Candidate Portal
- [x] CandidateAccount model (optional login)
- [x] Application status visibility
- [x] InterviewSelfSchedule with secure tokens
- [x] CandidateDocument model for file uploads
- [x] Multi-application management

**Deliverable:** Candidates have a full-featured portal with self-service capabilities.

---

## Phase 4: Offers & Compliance - COMPLETE

Goal: Complete hiring workflow with compliance controls.

**Status: DELIVERED** - 819 tests passing (120 new)

### 4.1 Offer Management
- [x] OfferTemplate with Liquid variable substitution
- [x] Offer model: salary, bonus, equity, start_date
- [x] OfferApproval workflow with sequenced approvers
- [x] Offer status: draft → pending_approval → approved → sent → accepted/declined/withdrawn/expired

### 4.2 E-Signature
- [ ] Integration with DocuSign or HelloSign (deferred to Phase 8)
- [x] Signed document storage via CandidateDocument

### 4.3 Compliance Data Capture
- [x] EeocResponse model (voluntary, post-apply)
- [x] GdprConsent tracking per candidate per type
- [x] DataRetentionPolicy engine
- [x] DeletionRequest workflow with identity verification

### 4.4 Adverse Action (FCRA)
- [x] AdverseAction model with state machine
- [x] Pre-adverse action notice workflow
- [x] 5 business day waiting period calculation
- [x] AdverseActionDispute tracking
- [x] Final adverse action documentation

**Deliverable:** Compliant offer process with audit-ready documentation.

---

## Phase 5: Intelligence & Automation - COMPLETE

Goal: Reduce recruiter workload through smart automation.

**Status: DELIVERED** - 944 tests passing (125 new)

### 5.1 Resume Parsing
- [x] ParsedResume model for structured extraction
- [x] ResumeParsingService (pluggable provider interface)
- [x] CandidateSkill model (parsed/self-reported/inferred)
- [x] Parsed data review/correction UI

### 5.2 Search & Talent Pools
- [x] SavedSearch model with boolean query support
- [x] SearchAlert for automated notifications
- [x] TalentPool model (manual and smart pools)
- [x] TalentPoolMember with source tracking

### 5.3 Automation Rules
- [x] AutomationRule model with conditions and actions
- [x] Knockout question automation (auto-reject)
- [x] Stage progression triggers
- [x] SLA alerts (candidates stuck in stage)
- [x] AutomationLog for execution tracking

### 5.4 Ranking & Recommendations
- [x] JobRequirement model for match criteria
- [x] CandidateScore model with breakdown
- [x] CandidateScoringService with explanations
- [x] Resume-to-job match scoring (assistive, explainable)

**Deliverable:** Recruiters spend less time on manual tasks, more time on high-value candidate interactions.

---

## Phase 6: Integrations & API - COMPLETE

Goal: Ecosystem connectivity.

**Status: DELIVERED** - 1162 tests passing (218 new)

### 6.1 Job Board Distribution
- [x] Integration model for external services
- [x] JobBoardPosting model for syndication tracking
- [x] Indeed integration (via Integration framework)
- [x] XML feed for aggregators

### 6.2 HRIS Export
- [x] HrisExport model for tracking exports
- [x] Workday integration support
- [x] Generic CSV/API export

### 6.3 Background Screening
- [x] BackgroundCheck model with state machine
- [x] Ledgoria integration framework
- [x] Checkr integration support
- [x] Result callback handling

### 6.4 Public API
- [x] ApiKey model with scopes
- [x] Rate limiting (per-minute/hour/day)
- [x] Webhook model for event delivery
- [x] WebhookDelivery tracking with retries
- [x] Exponential backoff for failures

### 6.5 SSO
- [x] SsoConfiguration model
- [x] SAML 2.0 support
- [x] OIDC support
- [x] SsoIdentity linking

### 6.6 Activity Logging
- [x] IntegrationLog for all external calls
- [x] Request/response capture
- [x] Error tracking

**Deliverable:** ATS connects to customer's existing HR tech stack.

---

## Phase 7: Analytics & Reporting - COMPLETE

Goal: Data-driven hiring insights.

**Status: DELIVERED** - 1236 tests passing (74 new)

### 7.1 Core Metrics
- [x] ApplicationQuery base class with Dry::Initializer
- [x] TimeToHireQuery (by job, department, source)
- [x] SourceEffectivenessQuery (applications, hires, conversion rate)
- [x] PipelineConversionQuery (stage-to-stage)
- [x] OfferAcceptanceQuery
- [x] DateRangeFilter concern for all reports
- [x] CSV export for all reports
- [x] Chart.js integration via Stimulus

### 7.2 Diversity & Compliance Reporting
- [x] EeocReportQuery with anonymization (< 5 = "< 5")
- [x] DiversityMetricsQuery with Simpson's diversity index
- [x] AdverseImpactQuery implementing 4/5ths rule
- [x] Admin-only access controls
- [x] PDF export via Prawn

### 7.3 Operational Dashboards
- [x] RecruiterProductivityQuery (activity metrics)
- [x] RequisitionAgingQuery (time-to-fill tracking)
- [x] ReportSnapshot model for caching expensive calculations
- [x] GenerateReportSnapshotJob for background processing

### 7.4 Reports Infrastructure
- [x] Reports::BaseController with shared concerns
- [x] 7 report controllers (Dashboard, TimeToHire, Sources, Pipeline, Operational, EEOC, Diversity)
- [x] ReportPolicy for authorization
- [x] Reports navigation menu

**Deliverable:** Hiring leaders have visibility into pipeline health and process efficiency.

---

## Differentiator: Identity & Trust (Ledgoria Integration)

This is your competitive moat. Build it into the core architecture from Phase 1.

### Trust Signals
- [x] Background check integration (Phase 6)
- [ ] Verified identity before offer
- [ ] Credential attestations (education, employment)
- [ ] Portable candidate trust profiles
- [ ] Reduced re-screening for returning candidates

### Compliance Advantage
- [x] Built-in adverse action workflows tied to screening
- [x] Structured decision justification (HiringDecision)
- [ ] Jurisdiction-aware hiring rules
- [x] Defensible audit artifacts

---

## Technical Architecture Decisions

### Stack
- **Backend:** Ruby on Rails 8.0.2
- **Ruby:** 3.4.5
- **Database:** PostgreSQL (production), SQLite (development)
- **Background Jobs:** Solid Queue (Rails 8 default)
- **Caching:** Solid Cache
- **Real-time:** Turbo Streams + Solid Cable
- **Frontend:** Hotwire (Turbo + Stimulus), Bootstrap 5.3 (CDN)
- **File Storage:** Active Storage (S3 in production)
- **PDF Generation:** Prawn
- **Search:** Database queries (PostgreSQL full-text available)

### Key Patterns
```
app/
├── models/           # ActiveRecord models with concerns
├── controllers/      # RESTful controllers
├── services/         # Business logic (Dry::Monads)
├── queries/          # Read-only query objects (Dry::Initializer)
├── policies/         # Authorization (Pundit)
├── jobs/             # Background jobs (Solid Queue)
├── mailers/          # Email delivery
└── views/            # ERB templates with Hotwire
```

### Multi-tenancy
- Account/Organization scoping from day one
- Row-level security via `Current.organization`
- OrganizationScoped concern for automatic scoping

### API Design
- RESTful resources
- JSON responses with format negotiation
- API key authentication with rate limiting
- Webhook system for external events

---

## Project Summary

| Phase | Theme | Status | Tests | Points |
|-------|-------|--------|-------|--------|
| 1 | Foundation MVP | COMPLETE | 431 | 325 |
| 2 | Scheduling & Evaluation | COMPLETE | 636 | 135 |
| 3 | Enhanced Candidate Experience | COMPLETE | 699 | 50 |
| 4 | Offers & Compliance | COMPLETE | 819 | 70 |
| 5 | Intelligence & Automation | COMPLETE | 944 | 80 |
| 6 | Integrations & API | COMPLETE | 1162 | 100 |
| 7 | Analytics & Reporting | COMPLETE | 1236 | 110 |
| 8 | I-9 & Work Authorization | COMPLETE | 1415 | 120 |
| **Total** | | **8 Phases** | **1415** | **990** |

---

## Go-to-Market Considerations

### Initial Target
- SMB companies (50-500 employees)
- High-compliance industries (finance, healthcare, government contractors)
- Companies already using or considering Ledgoria for background checks

### Pricing Model (TBD)
- Per-seat (recruiter/hiring manager)
- Per-job posting
- Tiered by features

### Competitive Positioning
- "Compliance-first ATS with built-in identity verification"
- "Reduce time-to-hire while increasing hiring defensibility"
- "The only ATS with native trust infrastructure"

---

## Phase 8: I-9 & Work Authorization - COMPLETE

Goal: First-class I-9 verification as core operational capability (per Ledgoria Voice strategic direction).

**Status: DELIVERED** - 1415 tests passing (179 new)

### 8.1 I-9 Core Models (Sprint 17 - COMPLETE)
- [x] I9Verification model with state machine (pending_section1 → verified)
- [x] WorkAuthorization model with expiration tracking
- [x] I9Document model for List A/B/C documents
- [x] EVerifyCase model for E-Verify integration
- [x] Business day deadline calculations (3 days for Section 2)
- [x] Encrypted sensitive fields (alien_number, i94_number, passport)
- [x] Service objects: InitiateI9VerificationService, CompleteI9Section1Service, CompleteI9Section2Service
- [x] Background jobs: I9NotificationJob, I9DeadlineReminderJob, WorkAuthorizationExpirationJob
- [x] Mailers: I9Mailer, WorkAuthorizationMailer

### 8.2 Section 2/3 & Dashboard (Sprint 18 - COMPLETE)
- [x] Admin::I9VerificationsController for HR
- [x] Section 2 document verification workflow
- [x] Section 3 reverification workflow
- [x] I9ComplianceQuery for dashboard
- [x] Reports::I9ComplianceController
- [x] Reports::WorkAuthorizationsController
- [x] Work authorization expiration dashboard
- [x] CandidatePortal::I9VerificationsController for Section 1
- [x] I9VerificationPolicy and WorkAuthorizationPolicy

**Phase 8 Total: 120 points, 179 new tests (1415 cumulative)**

---

## Future Roadmap

### Phase 9: E-Signature & Documents (Planned)
- DocuSign/HelloSign integration
- Document templates with merge fields
- Bulk document generation
- Document expiration tracking

### Phase 10: Advanced Integrations (Planned)
- LinkedIn Recruiter integration
- Slack/Teams notifications
- Video interview platforms (Zoom, Teams)
- Assessment platforms (HackerRank, Codility)

### Phase 11: Mobile & AI (Planned)
- Native mobile apps (iOS/Android)
- AI-powered candidate screening
- Interview scheduling assistant
- Predictive analytics

---

## Open Questions (Resolved)

1. **Multi-tenancy model:** ✅ Single domain with org scoping via Current.organization
2. **Resume parsing:** ✅ Pluggable service interface (build adapter for vendor)
3. **Calendar integration:** ✅ Google-first, Outlook supported via CalendarIntegration model
4. **Mobile:** ✅ Responsive web, native apps in Phase 10
5. **Pricing:** TBD - seat-based likely
6. **Initial market:** ✅ US-first, international compliance in future phase
