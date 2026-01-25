# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ledgoria is a compliance-first Applicant Tracking System (ATS) with native identity verification and background screening integration.

**Phase 1 MVP is COMPLETE** with 431 passing tests. All 6 sprints delivered:
- Multi-tenant organization support with RBAC
- Job requisitions with approval workflow
- Kanban pipeline with drag-drop
- Candidate management with PII encryption
- Immutable audit trail and compliance logging
- Public career site with application flow
- Email notifications for applicants

**Phase 2 Scheduling & Evaluation is COMPLETE** with 636 passing tests. 3 sprints delivered:
- Sprint 7: Interview Scheduling - Interview model with state machine, participants, calendar integrations
- Sprint 8: Scorecards & Feedback - Scorecard templates, sections, items, responses with visibility rules
- Sprint 9: Interview Kits & Decisions - Question banks, interview kits, immutable hiring decisions

**Phase 3 Enhanced Candidate Experience is COMPLETE** with 699 passing tests. 1 sprint delivered:
- Sprint 10: Candidate Experience - Organization branding, custom application questions, candidate accounts, document management, interview self-scheduling

**Phase 4 Offers & Compliance is COMPLETE** with 819 passing tests. 2 sprints delivered:
- Sprint 11: Offer Management - Offer templates with variable substitution, offer workflow (draft → approval → sent → accepted), multi-step approval chain
- Sprint 12: Compliance - EEOC voluntary self-identification, GDPR consent tracking, data retention policies, right-to-deletion workflow, FCRA adverse action workflow

**Phase 5 Intelligence & Automation is COMPLETE** with 944 passing tests. 1 sprint delivered:
- Sprint 13: Intelligence - Resume parsing, candidate skills extraction, saved searches with alerts, talent pools (manual and smart), automation rules (knockout, stage progression, SLA alerts), candidate-job match scoring with explanations, job requirements for matching

**Phase 6 Integrations & API is COMPLETE** with 1162 passing tests. 1 sprint delivered:
- Sprint 14: Integrations - External integrations framework (job boards, HRIS, background checks), outbound webhooks with retry logic and exponential backoff, API key management with rate limiting (per-minute/hour/day), SAML 2.0 and OIDC SSO authentication, integration activity logging, background check workflow, HRIS export tracking, job board posting sync

**Phase 7 Analytics & Reporting is COMPLETE** with 1236 passing tests. 2 sprints delivered:
- Sprint 15: Core Metrics - ApplicationQuery base class, DateRangeFilter concern, TimeToHireQuery, SourceEffectivenessQuery, PipelineConversionQuery, OfferAcceptanceQuery, RecruiterProductivityQuery, RequisitionAgingQuery, Chart.js integration, CSV export for all reports
- Sprint 16: Diversity & Compliance - ReportSnapshot model for caching, EeocReportQuery with anonymization, DiversityMetricsQuery with Simpson's diversity index, AdverseImpactQuery implementing 4/5ths rule, PDF export via Prawn, admin-only diversity/EEOC reports

**Phase 8 I-9 and Work Authorization is COMPLETE** with 1415 passing tests. 2 sprints delivered:
- Sprint 17: I-9 Core Models - I9Verification model with state machine (pending_section1 → section1_complete → pending_section2 → section2_complete → verified), WorkAuthorization model with expiration tracking, I9Document model for List A/B/C documents, EVerifyCase model for E-Verify integration, business day deadline calculations, encryption for sensitive fields (alien_number, i94_number, foreign_passport_number)
- Sprint 18: Section 2/3 & Dashboard - Admin::I9VerificationsController for HR verification workflow, Admin::WorkAuthorizationsController for expiration tracking, Reports::I9ComplianceController with I9ComplianceQuery for compliance metrics, Reports::WorkAuthorizationsController for authorization tracking, candidate portal Section 1 completion, I9VerificationPolicy and WorkAuthorizationPolicy for access control

## Tech Stack

- **Ruby:** 3.4.5
- **Rails:** 8.0.2
- **Database:** SQLite (development/test), PostgreSQL (production)
- **Background Jobs:** Solid Queue
- **Real-time:** Solid Cable (Action Cable)
- **Caching:** Solid Cache
- **Frontend:** Hotwire (Turbo + Stimulus), Bootstrap 5.3 (via CDN)
- **Testing:** Minitest + FactoryBot
- **File Storage:** Active Storage (local dev, S3 production)
- **Deployment:** AWS Elastic Beanstalk + CloudFormation (aligned with ledgoria_collect)

## Database Compatibility

**Important:** Development uses SQLite, production uses PostgreSQL.

When writing migrations:
- Use `json` type, NOT `jsonb` (SQLite doesn't support jsonb)
- Don't add explicit indexes for columns created by `t.references` (Rails auto-creates them)
- Test migrations with `bin/rails db:migrate:reset` before committing

JSON columns work identically in both databases for our use cases. If advanced PostgreSQL JSON querying is needed later, we can add a production-only migration.

## Common Commands

```bash
# Install dependencies
bundle install

# Start development server
bin/dev

# Start Rails server
bin/rails server

# Start Rails console
bin/rails console

# Run database migrations
bin/rails db:migrate

# Reset database (drop, create, migrate)
bin/rails db:migrate:reset

# Seed development data (requires models)
bin/rails db:seed

# Run all tests
bin/rails test

# Run a single test file
bin/rails test test/models/user_test.rb

# Run a specific test by line number
bin/rails test test/models/user_test.rb:10

# Run system tests
bin/rails test:system

# Lint code
bin/rubocop

# Lint with auto-fix
bin/rubocop -a

# Security scan
bin/brakeman

# Background job processor
bin/jobs
```

## Architecture

### Modular Monolith with Bounded Contexts

The application follows a modular monolith architecture organized by 12 bounded contexts (subject areas). When implementation begins, the structure will be:

```
app/domains/
├── iam/           # SA-01: Identity & Access (User, Role, Permission)
├── organization/  # SA-02: Organization (Org settings, Departments, Stages)
├── requisition/   # SA-03: Job Requisition (Jobs, Approvals, Postings)
├── candidate/     # SA-04: Candidate (Profiles, Resumes, Talent Pools)
├── pipeline/      # SA-05: Application Pipeline (Applications, Stage Transitions)
├── interview/     # SA-06: Interview (Scheduling, Calendar, Participants)
├── evaluation/    # SA-07: Evaluation (Scorecards, Hiring Decisions)
├── offer/         # SA-08: Offer Management (Offers, Approvals, E-signature)
├── compliance/    # SA-09: Compliance & Audit (EEOC, GDPR, Background Checks)
├── communication/ # SA-10: Communication (Email, Notifications, SMS)
├── integration/   # SA-11: Integration (Job Boards, HRIS, Webhooks)
└── career_site/   # SA-12: Career Site (Public site, Application flow)
```

Each domain module follows this internal structure:
```
domains/{context}/
├── models/      # ActiveRecord models
├── services/    # Business logic services
├── events/      # Domain events
├── policies/    # Authorization (Pundit)
├── queries/     # Complex read queries
└── validators/  # Custom validators
```

### Multi-Tenancy

All tenant-scoped models include `organization_id` and use `Current.organization` for scoping. Never query without organization context.

### Key Architectural Decisions

1. **Modular Monolith First** - Bounded contexts in single app, extract services later
2. **Event-Driven Integration** - Contexts communicate via domain events
3. **Field-Level Encryption** - Use Rails `encrypts` for PII (email, phone, salary, SSN)
4. **Immutable Audit Trail** - AuditLog, StageTransition, HiringDecision never updated

## Documentation

Key documentation in `docs/`:

- `ARCHITECTURE.md` - System architecture, infrastructure, ADRs
- `DATA_MODEL.md` - Complete data model with 12 bounded contexts
- `USE_CASES.md` - 100+ use cases with mermaid diagrams
- `ACTORS.md` - System actors and permission matrix
- `CONOPS.md` - Concept of operations, UX design
- `PRODUCT_PLAN.md` - 7-phase product roadmap
- `BUSINESS_CASE.md` - Investment case and financials
- `TEST_STRATEGY.md` - Testing approach and coverage requirements
- `SPRINT_BACKLOG.md` - Phase 1 sprint breakdown
- `wireframes/` - Low-fidelity UI wireframes
- `use-cases/` - Detailed use case specifications
- `retrospectives/` - Sprint retrospectives

## Development Notes

### Multi-Tenancy Pattern
All tenant-scoped models include `OrganizationScoped` concern which:
- Adds `belongs_to :organization`
- Sets `organization_id` from `Current.organization` on create
- Applies default scope filtering by current organization

Example:
```ruby
class MyModel < ApplicationRecord
  include OrganizationScoped
end
```

### Authentication (Devise)
Users are authenticated via Devise with these modules:
- `database_authenticatable`, `recoverable`, `rememberable`
- `validatable`, `trackable`, `lockable`, `confirmable`

Email confirmation is only required in production (`confirmation_required?` overridden).

### Authorization (Pundit)
All policies inherit from `ApplicationPolicy` which provides:
- `same_organization?` - Checks record belongs to user's org
- `admin?`, `recruiter?`, `hiring_manager?` - Role helpers
- Default scope that filters by organization_id

### Fixtures and JSON Columns
When writing fixtures for models with JSON columns, use YAML native syntax for arrays:
```yaml
# Use YAML arrays for JSON array columns
options:
  - "Option 1"
  - "Option 2"
  - "Option 3"

# Or JSON string format for complex objects
permissions: '{"users": ["read", "write"]}'
settings: '{}'
```

### Naming Conflicts
Avoid naming associations the same as JSON column names. For example, if a model has a `permissions` JSON column, name the association `linked_permissions` instead of `permissions`.

### State Machines
Several models use the `state_machines-activerecord` gem for workflow management:
- `Application` - new → screening → interviewing → assessment → background_check → offered → hired/rejected/withdrawn
- `Interview` - scheduled → confirmed → completed/cancelled/no_show
- `Scorecard` - draft → submitted → locked

Avoid naming state machine events that conflict with ActiveRecord methods (e.g., use `lock_scorecard` instead of `lock`).

### Immutable Models
Some models are immutable and cannot be updated or deleted after creation:
- `AuditLog` - Audit trail entries
- `StageTransition` - Application stage change history
- `HiringDecision` - Hire/reject/hold decisions (approval workflow uses `update_columns` to bypass)

For `HiringDecision`, use `dependent: :restrict_with_error` on associations to prevent cascade deletes.

### Candidate Authentication (Devise)
Candidates have separate Devise authentication via `CandidateAccount`:
- Allows candidates to optionally create accounts to track their applications
- Uses separate Devise scope (`devise_for :candidate_accounts`)
- Portal routes are namespaced under `/portal`
- Token-based access (e.g., self-scheduling) works without requiring login

### Token-Based Access
Some features use secure tokens for public access without authentication:
- `InterviewSelfSchedule` - candidates receive a unique token URL to select interview slots
- Tokens are generated with `SecureRandom.urlsafe_base64(32)` for security
- Token-based routes are public but scoped to specific actions

### Service Objects
Business logic is encapsulated in service objects using `Dry::Monads`:
```ruby
class MyService < ApplicationService
  option :param1
  option :param2, default: -> { nil }

  def call
    yield validate_input
    result = yield perform_action
    Success(result)
  end
end

# Usage
result = MyService.call(param1: value)
if result.success?
  result.value!
else
  result.failure
end
```

### Query Objects
Complex read queries are encapsulated in query objects using `Dry::Initializer`:
```ruby
class MyQuery < ApplicationQuery
  option :start_date
  option :end_date
  option :job_id, optional: true

  def call
    {
      summary: calculate_summary,
      details: calculate_details
    }
  end
end

# Usage
result = MyQuery.call(start_date: 30.days.ago, end_date: Time.current)
```

Query objects are read-only and scoped to `Current.organization` automatically.

### Compliance Workflows

**Offer Workflow:**
- `Offer` follows: draft → pending_approval → approved → sent → accepted/declined/withdrawn/expired
- Multi-step approval via `OfferApproval` with sequenced approvers
- Template-based rendering with variable substitution

**GDPR Compliance:**
- `GdprConsent` tracks consent per candidate per type (data_processing, marketing, etc.)
- Consent can be granted and withdrawn with full audit trail
- `DeletionRequest` implements right-to-deletion with identity verification and legal hold

**FCRA Adverse Action:**
- `AdverseAction` follows FCRA requirements: draft → pre_adverse_sent → waiting_period → final_sent → completed
- 5 business day waiting period calculated automatically
- Dispute tracking during waiting period

## Deployment

### Infrastructure (Elastic Beanstalk)
Aligned with ledgoria_collect patterns for consistency across Ledgoria portfolio.

**MVP Environment Model:**
- Single production environment (no separate staging)
- Shared `ledgoria-aux` VPC with ledgoria_collect
- Shared RDS instance with dedicated `ledgoria` schema
- Cost-optimized for rapid development until customer acquisition

**Configuration:**
```
.ebextensions/
├── 00_vpc.config        # VPC, subnets, security groups (SSM references)
├── 01_packages.config   # System dependencies
├── 02_rails.config      # Rails environment, DB config (SSM references)
├── 03_ssm.config        # AWS Systems Manager for secure access
├── 04_deployment.config # Rolling deployment (50% batch)
├── 05_health.config     # Health check at /up
└── 06_logs.config       # CloudWatch Logs (90-day retention)
```

**Security Note:** Infrastructure IDs use SSM Parameter Store references (`{{resolve:ssm:/ledgoria/...}}`) to keep sensitive values out of this public repository. Actual values are managed in the private `ledgoria-iac` repository.

**Authoritative Infrastructure Source:** `ledgoria-iac` repository (CloudFormation templates, deployment runbooks).
