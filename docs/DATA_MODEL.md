# Ledgoria - Data Model

## Overview

This document defines the data model organized by **subject areas** that map to bounded contexts in a domain-driven design. Each subject area represents a cohesive domain with clear boundaries, aggregates, and integration points.

---

## Subject Area Map

```mermaid
graph TB
    subgraph "Core Platform"
        IAM[Identity & Access]
        ORG[Organization Management]
    end

    subgraph "Recruiting Operations"
        JOB[Job Requisition]
        CAND[Candidate]
        APP[Application Pipeline]
    end

    subgraph "Hiring Process"
        INT[Interview]
        EVAL[Evaluation]
        OFFER[Offer Management]
    end

    subgraph "Supporting Services"
        COMP[Compliance & Audit]
        COMM[Communication]
        INTEG[Integration]
        CAREER[Career Site]
    end

    %% Core dependencies
    IAM --> ORG
    ORG --> JOB
    ORG --> CAND

    %% Recruiting flow
    JOB --> APP
    CAND --> APP

    %% Hiring flow
    APP --> INT
    INT --> EVAL
    APP --> OFFER

    %% Supporting services
    APP --> COMP
    OFFER --> COMP
    APP --> COMM
    JOB --> CAREER
    JOB --> INTEG
    CAND --> INTEG
```

---

## Subject Area Summary

| ID | Subject Area | Bounded Context | Aggregate Roots | Description |
|----|--------------|-----------------|-----------------|-------------|
| SA-01 | Identity & Access | `iam` | User, Role | Authentication, authorization, permissions |
| SA-02 | Organization | `org` | Organization, Department | Multi-tenancy, org structure, settings |
| SA-03 | Job Requisition | `requisition` | Job | Job lifecycle, approvals, posting |
| SA-04 | Candidate | `candidate` | Candidate | Candidate profiles, resumes, talent pools |
| SA-05 | Application Pipeline | `pipeline` | Application | Applications, stages, workflow |
| SA-06 | Interview | `interview` | Interview | Scheduling, calendar, participants |
| SA-07 | Evaluation | `evaluation` | Scorecard | Feedback, competencies, decisions |
| SA-08 | Offer Management | `offer` | Offer | Offers, approvals, e-signature |
| SA-09 | Compliance & Audit | `compliance` | AuditLog, BackgroundCheck | EEOC, GDPR, screening, audit trail |
| SA-10 | Communication | `communication` | EmailLog | Templates, notifications, sequences |
| SA-11 | Integration | `integration` | IntegrationConfig | Job boards, HRIS, API, webhooks |
| SA-12 | Career Site | `career` | CareerSiteConfig | Public site, branding, application flow |

---

## Context Map

Shows relationships between bounded contexts:

```mermaid
graph LR
    subgraph "Upstream"
        IAM((Identity<br>& Access))
        ORG((Organization))
    end

    subgraph "Core Domain"
        JOB((Job<br>Requisition))
        CAND((Candidate))
        APP((Application<br>Pipeline))
    end

    subgraph "Supporting"
        INT((Interview))
        EVAL((Evaluation))
        OFFER((Offer))
    end

    subgraph "Generic"
        COMP((Compliance))
        COMM((Communication))
    end

    IAM -->|Conformist| ORG
    IAM -->|Conformist| JOB
    IAM -->|Conformist| APP

    ORG -->|Shared Kernel| JOB
    ORG -->|Shared Kernel| CAND

    JOB -->|Partnership| APP
    CAND -->|Partnership| APP

    APP -->|Customer-Supplier| INT
    APP -->|Customer-Supplier| OFFER
    INT -->|Customer-Supplier| EVAL

    APP -->|Published Language| COMP
    APP -->|Published Language| COMM
    OFFER -->|Published Language| COMP
```

### Context Relationships

| Upstream | Downstream | Pattern | Integration |
|----------|------------|---------|-------------|
| Identity & Access | All contexts | Conformist | Shared User/Org IDs |
| Organization | Job, Candidate | Shared Kernel | Org scoping |
| Job Requisition | Application | Partnership | Job reference |
| Candidate | Application | Partnership | Candidate reference |
| Application | Interview | Customer-Supplier | Application events |
| Application | Offer | Customer-Supplier | Application events |
| Interview | Evaluation | Customer-Supplier | Interview events |
| Application | Compliance | Published Language | Domain events |
| Application | Communication | Published Language | Domain events |

---

# SA-01: Identity & Access

## Context Overview

Handles authentication, authorization, user management, and access control. This is a **core subdomain** that all other contexts depend on.

## Aggregate: User

```mermaid
erDiagram
    User ||--o{ UserRole : has
    User ||--o{ UserSession : has
    User ||--o{ ApiKey : owns
    Role ||--o{ UserRole : assigned_to
    Role ||--o{ RolePermission : has
    Permission ||--o{ RolePermission : granted_by
    SsoConfig ||--o{ SsoIdentity : provides
    User ||--o{ SsoIdentity : has

    User {
        bigint id PK
        bigint organization_id FK
        string email UK
        string encrypted_password
        string first_name
        string last_name
        string avatar_url
        boolean active
        datetime confirmed_at
        datetime last_sign_in_at
        string last_sign_in_ip
        integer sign_in_count
        datetime password_changed_at
        datetime locked_at
        integer failed_attempts
        string unlock_token
        datetime created_at
        datetime updated_at
    }

    Role {
        bigint id PK
        bigint organization_id FK
        string name UK
        string description
        boolean system_role
        jsonb permissions
        datetime created_at
        datetime updated_at
    }

    UserRole {
        bigint id PK
        bigint user_id FK
        bigint role_id FK
        datetime granted_at
        bigint granted_by_id FK
        datetime created_at
    }

    Permission {
        bigint id PK
        string resource
        string action
        string description
        datetime created_at
    }

    RolePermission {
        bigint id PK
        bigint role_id FK
        bigint permission_id FK
        jsonb conditions
        datetime created_at
    }

    UserSession {
        bigint id PK
        bigint user_id FK
        string token_digest UK
        string ip_address
        string user_agent
        datetime expires_at
        datetime last_active_at
        datetime created_at
    }

    ApiKey {
        bigint id PK
        bigint user_id FK
        bigint organization_id FK
        string name
        string key_prefix
        string key_digest UK
        jsonb scopes
        datetime last_used_at
        datetime expires_at
        datetime revoked_at
        datetime created_at
    }

    SsoConfig {
        bigint id PK
        bigint organization_id FK
        string provider
        string issuer_url
        string client_id
        string client_secret_encrypted
        jsonb metadata
        boolean enabled
        datetime created_at
        datetime updated_at
    }

    SsoIdentity {
        bigint id PK
        bigint user_id FK
        bigint sso_config_id FK
        string provider_uid UK
        jsonb provider_data
        datetime last_used_at
        datetime created_at
    }
```

## Entities

### User (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| email | string | NOT NULL, UNIQUE(org) | Login email |
| encrypted_password | string | NULL | Hashed password (null if SSO-only) |
| first_name | string | NOT NULL | First name |
| last_name | string | NOT NULL | Last name |
| avatar_url | string | NULL | Profile image URL |
| active | boolean | NOT NULL, DEFAULT true | Account active flag |
| confirmed_at | datetime | NULL | Email confirmation time |
| last_sign_in_at | datetime | NULL | Last login timestamp |
| last_sign_in_ip | string | NULL | Last login IP |
| sign_in_count | integer | DEFAULT 0 | Total login count |
| password_changed_at | datetime | NULL | Last password change |
| locked_at | datetime | NULL | Account lock time |
| failed_attempts | integer | DEFAULT 0 | Failed login attempts |
| unlock_token | string | NULL | Account unlock token |

### Role

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| name | string | NOT NULL, UNIQUE(org) | Role name |
| description | string | NULL | Role description |
| system_role | boolean | DEFAULT false | System-defined (not deletable) |
| permissions | jsonb | NOT NULL | Permission set |

**System Roles:**
- `admin` - Full system access
- `recruiter` - Full recruiting access
- `hiring_manager` - Job and candidate management for own jobs
- `interviewer` - Interview and feedback access
- `readonly` - View-only access

### Permission

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| resource | string | NOT NULL | Resource type (job, candidate, etc.) |
| action | string | NOT NULL | Action (create, read, update, delete) |
| description | string | NULL | Human-readable description |

**Permission Examples:**
- `job:create`, `job:read`, `job:update`, `job:delete`
- `candidate:read`, `candidate:update`
- `application:move_stage`, `application:reject`
- `offer:approve`
- `report:view_diversity`

---

# SA-02: Organization Management

## Context Overview

Manages multi-tenancy, organizational structure, and organization-wide settings. This is the **tenant boundary** for the entire system.

## Aggregate: Organization

```mermaid
erDiagram
    Organization ||--o{ Department : has
    Organization ||--o{ OrganizationSetting : has
    Organization ||--o{ Stage : defines
    Organization ||--o{ RejectionReason : defines
    Organization ||--o{ Competency : defines
    Organization ||--o{ CustomField : defines
    Organization ||--o{ LookupType : defines
    LookupType ||--o{ LookupValue : contains
    Department ||--o{ Department : parent_of

    Organization {
        bigint id PK
        string name
        string subdomain UK
        string domain
        string logo_url
        string timezone
        string default_currency
        string default_locale
        jsonb settings
        string billing_email
        string plan
        datetime trial_ends_at
        datetime created_at
        datetime updated_at
        datetime discarded_at
    }

    Department {
        bigint id PK
        bigint organization_id FK
        bigint parent_id FK
        string name
        string code
        integer position
        bigint default_hiring_manager_id FK
        datetime created_at
        datetime updated_at
    }

    OrganizationSetting {
        bigint id PK
        bigint organization_id FK
        string key UK
        jsonb value
        datetime created_at
        datetime updated_at
    }

    Stage {
        bigint id PK
        bigint organization_id FK
        string name
        string stage_type
        integer position
        boolean is_terminal
        boolean is_default
        string color
        datetime created_at
        datetime updated_at
    }

    RejectionReason {
        bigint id PK
        bigint organization_id FK
        string name
        string category
        boolean requires_notes
        boolean active
        integer position
        datetime created_at
        datetime updated_at
    }

    Competency {
        bigint id PK
        bigint organization_id FK
        string name
        string description
        string category
        boolean active
        datetime created_at
        datetime updated_at
    }

    CustomField {
        bigint id PK
        bigint organization_id FK
        string entity_type
        string field_key
        string label
        string field_type
        jsonb options
        boolean required
        integer position
        boolean active
        datetime created_at
        datetime updated_at
    }

    LookupType {
        bigint id PK
        bigint organization_id FK
        string code UK
        string name
        string description
        boolean system_managed
        boolean active
        datetime created_at
        datetime updated_at
    }

    LookupValue {
        bigint id PK
        bigint lookup_type_id FK
        string code
        jsonb translations
        jsonb metadata
        integer position
        boolean active
        boolean is_default
        datetime created_at
        datetime updated_at
    }
```

## Entities

### Organization (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| name | string | NOT NULL | Organization name |
| subdomain | string | UNIQUE, NOT NULL | URL subdomain |
| domain | string | NULL | Custom domain |
| logo_url | string | NULL | Logo image URL |
| timezone | string | DEFAULT 'UTC' | Default timezone |
| default_currency | string | DEFAULT 'USD' | Default currency |
| default_locale | string | DEFAULT 'en' | Default locale |
| settings | jsonb | NOT NULL | Organization settings |
| billing_email | string | NULL | Billing contact |
| plan | string | DEFAULT 'trial' | Subscription plan |
| trial_ends_at | datetime | NULL | Trial expiration |
| discarded_at | datetime | NULL | Soft delete timestamp |

**Settings JSON Structure:**
```json
{
  "require_job_approval": true,
  "require_offer_approval": true,
  "rejection_notification_delay_hours": 48,
  "eeoc_collection_enabled": true,
  "gdpr_mode": false,
  "background_check_provider": "ledgoria",
  "calendar_provider": "google"
}
```

### Department

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| parent_id | bigint | FK, NULL | Parent department (hierarchy) |
| name | string | NOT NULL | Department name |
| code | string | NULL | Department code |
| position | integer | DEFAULT 0 | Sort order |
| default_hiring_manager_id | bigint | FK, NULL | Default HM for new jobs |

### Stage

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| name | string | NOT NULL | Stage name |
| stage_type | enum | NOT NULL | applied, screening, interview, offer, hired, rejected |
| position | integer | NOT NULL | Sort order |
| is_terminal | boolean | DEFAULT false | End state flag |
| is_default | boolean | DEFAULT false | Include in new jobs |
| color | string | NULL | UI display color |

### RejectionReason

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| name | string | NOT NULL | Reason display name |
| category | enum | NOT NULL | not_qualified, timing, compensation, culture_fit, withdrew, other |
| requires_notes | boolean | DEFAULT false | Force notes entry |
| active | boolean | DEFAULT true | Available for selection |
| position | integer | DEFAULT 0 | Sort order |

### Competency

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| name | string | NOT NULL | Competency name |
| description | string | NULL | Detailed description |
| category | enum | NULL | technical, behavioral, cultural, role_specific |
| active | boolean | DEFAULT true | Available for use |

### CustomField

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| entity_type | enum | NOT NULL | candidate, job, application |
| field_key | string | NOT NULL | Internal key |
| label | string | NOT NULL | Display label |
| field_type | enum | NOT NULL | text, number, date, select, multiselect, boolean |
| options | jsonb | NULL | Select options |
| required | boolean | DEFAULT false | Required field |
| position | integer | DEFAULT 0 | Sort order |
| active | boolean | DEFAULT true | Field enabled |

### LookupType

Reference data categories for configurable dropdown values. Supports i18n through LookupValue translations.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| code | string | UNIQUE per org, NOT NULL | Internal key (e.g., employment_type, location_type) |
| name | string | NOT NULL | Admin display name |
| description | string | NULL | Help text for admins |
| system_managed | boolean | DEFAULT false | If true, values cannot be deleted |
| active | boolean | DEFAULT true | Type enabled |

**Standard Lookup Types:**
- `employment_type` - Full-time, Part-time, Contract, etc.
- `location_type` - Remote, Onsite, Hybrid
- `application_source` - Career site, Job board, Referral, etc.
- `note_visibility` - Private, Team, Hiring team
- `rejection_category` - Not qualified, Timing, Compensation, etc.

### LookupValue

Individual values within a lookup type, with multi-locale translations stored in JSON.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| lookup_type_id | bigint | FK, NOT NULL | Parent lookup type |
| code | string | UNIQUE per type, NOT NULL | Internal key (e.g., full_time) |
| translations | jsonb | NOT NULL | Locale-keyed display names |
| metadata | jsonb | NULL | Additional data (e.g., icon, color) |
| position | integer | DEFAULT 0 | Sort order |
| active | boolean | DEFAULT true | Value enabled |
| is_default | boolean | DEFAULT false | Default selection |

**Translations JSON Structure:**
```json
{
  "en": { "name": "Full-time", "description": "Regular full-time employment" },
  "es": { "name": "Tiempo completo", "description": "Empleo regular a tiempo completo" },
  "fr": { "name": "Temps plein", "description": "Emploi régulier à temps plein" }
}
```

**Metadata JSON Structure (optional):**
```json
{
  "icon": "bi-briefcase",
  "color": "#3B82F6",
  "requires_location": true
}
```

**Locale Fallback:** When a translation is missing for the requested locale, the system falls back to the organization's `default_locale`, then to `en`.

---

# SA-03: Job Requisition

## Context Overview

Manages the job requisition lifecycle from creation through posting to closure. This is a **core domain** that drives the recruiting process.

## Aggregate: Job

```mermaid
erDiagram
    Job ||--o{ JobApproval : requires
    Job ||--o{ JobStage : has
    Job ||--o{ JobBoardPosting : posted_to
    Job ||--o{ JobCustomFieldValue : has
    Job }o--|| Department : belongs_to
    Job }o--|| User : hiring_manager
    Job }o--|| User : recruiter
    JobStage }o--|| Stage : references

    Job {
        bigint id PK
        bigint organization_id FK
        bigint department_id FK
        bigint hiring_manager_id FK
        bigint recruiter_id FK
        string title
        text description
        text requirements
        text internal_notes
        string location
        string location_type
        string employment_type
        integer salary_min
        integer salary_max
        string salary_currency
        boolean salary_visible
        string status
        datetime opened_at
        datetime closed_at
        string close_reason
        integer headcount
        integer filled_count
        string remote_id
        datetime created_at
        datetime updated_at
        datetime discarded_at
    }

    JobApproval {
        bigint id PK
        bigint job_id FK
        bigint approver_id FK
        string status
        text notes
        integer sequence
        datetime decided_at
        datetime created_at
        datetime updated_at
    }

    JobStage {
        bigint id PK
        bigint job_id FK
        bigint stage_id FK
        integer position
        boolean required_interview
        bigint scorecard_template_id FK
        datetime created_at
        datetime updated_at
    }

    JobBoardPosting {
        bigint id PK
        bigint job_id FK
        string board_name
        string external_id
        string external_url
        string status
        datetime posted_at
        datetime expires_at
        datetime removed_at
        jsonb metadata
        datetime created_at
        datetime updated_at
    }

    JobCustomFieldValue {
        bigint id PK
        bigint job_id FK
        bigint custom_field_id FK
        text value
        datetime created_at
        datetime updated_at
    }
```

## Entities

### Job (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| department_id | bigint | FK, NULL | Department |
| hiring_manager_id | bigint | FK, NULL | Hiring manager user |
| recruiter_id | bigint | FK, NULL | Assigned recruiter |
| title | string | NOT NULL | Job title |
| description | text | NULL | Public job description |
| requirements | text | NULL | Job requirements |
| internal_notes | text | NULL | Internal-only notes |
| location | string | NULL | Job location |
| location_type | enum | NOT NULL | onsite, remote, hybrid |
| employment_type | enum | NOT NULL | full_time, part_time, contract, intern |
| salary_min | integer | NULL | Minimum salary (cents) |
| salary_max | integer | NULL | Maximum salary (cents) |
| salary_currency | string | DEFAULT 'USD' | Salary currency |
| salary_visible | boolean | DEFAULT false | Show salary on career site |
| status | enum | NOT NULL | draft, pending_approval, open, on_hold, closed |
| opened_at | datetime | NULL | When job opened |
| closed_at | datetime | NULL | When job closed |
| close_reason | enum | NULL | filled, cancelled, on_hold |
| headcount | integer | DEFAULT 1 | Positions to fill |
| filled_count | integer | DEFAULT 0 | Positions filled |
| remote_id | string | NULL | External system reference |
| discarded_at | datetime | NULL | Soft delete |

**Status State Machine:**
```
draft → pending_approval → open ⇄ on_hold → closed
                            ↓
                          closed
```

### JobApproval

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| job_id | bigint | FK, NOT NULL | Parent job |
| approver_id | bigint | FK, NOT NULL | Approving user |
| status | enum | NOT NULL | pending, approved, rejected |
| notes | text | NULL | Approval notes |
| sequence | integer | DEFAULT 0 | Approval order |
| decided_at | datetime | NULL | Decision timestamp |

### JobStage

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| job_id | bigint | FK, NOT NULL | Parent job |
| stage_id | bigint | FK, NOT NULL | Stage reference |
| position | integer | NOT NULL | Order in pipeline |
| required_interview | boolean | DEFAULT false | Require interview at stage |
| scorecard_template_id | bigint | FK, NULL | Scorecard template for stage |

### JobBoardPosting

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| job_id | bigint | FK, NOT NULL | Parent job |
| board_name | string | NOT NULL | Job board identifier |
| external_id | string | NULL | ID from job board |
| external_url | string | NULL | URL on job board |
| status | enum | NOT NULL | pending, active, expired, removed, error |
| posted_at | datetime | NULL | Posted timestamp |
| expires_at | datetime | NULL | Expiration date |
| removed_at | datetime | NULL | Removal timestamp |
| metadata | jsonb | NULL | Board-specific data |

---

# SA-04: Candidate

## Context Overview

Manages candidate profiles, resumes, and talent pools. Candidates exist independently of specific job applications and can apply to multiple jobs.

## Aggregate: Candidate

```mermaid
erDiagram
    Candidate ||--o{ Resume : has
    Candidate ||--o{ CandidateNote : has
    Candidate ||--o{ CandidateTag : has
    Candidate ||--o{ CandidateCustomFieldValue : has
    Candidate ||--o{ CandidateSource : tracked_via
    Candidate }o--o| Candidate : merged_into
    Tag ||--o{ CandidateTag : applied_to
    TalentPool ||--o{ TalentPoolMember : contains
    Candidate ||--o{ TalentPoolMember : member_of
    Agency ||--o{ Candidate : submitted

    Candidate {
        bigint id PK
        bigint organization_id FK
        string first_name
        string last_name
        string email
        string phone
        string location
        string linkedin_url
        string portfolio_url
        text summary
        bigint referred_by_id FK
        bigint agency_id FK
        bigint merged_into_id FK
        datetime merged_at
        jsonb parsed_profile
        datetime created_at
        datetime updated_at
        datetime discarded_at
    }

    Resume {
        bigint id PK
        bigint candidate_id FK
        string filename
        string content_type
        integer file_size
        string storage_key
        text raw_text
        jsonb parsed_data
        boolean primary
        datetime parsed_at
        datetime created_at
        datetime updated_at
    }

    CandidateNote {
        bigint id PK
        bigint candidate_id FK
        bigint user_id FK
        text content
        string visibility
        boolean pinned
        datetime created_at
        datetime updated_at
    }

    Tag {
        bigint id PK
        bigint organization_id FK
        string name UK
        string color
        datetime created_at
    }

    CandidateTag {
        bigint id PK
        bigint candidate_id FK
        bigint tag_id FK
        bigint added_by_id FK
        datetime created_at
    }

    TalentPool {
        bigint id PK
        bigint organization_id FK
        string name
        text description
        bigint owner_id FK
        boolean shared
        datetime created_at
        datetime updated_at
    }

    TalentPoolMember {
        bigint id PK
        bigint talent_pool_id FK
        bigint candidate_id FK
        bigint added_by_id FK
        text notes
        datetime created_at
    }

    Agency {
        bigint id PK
        bigint organization_id FK
        string name
        string contact_email
        string contact_name
        decimal fee_percentage
        boolean active
        datetime created_at
        datetime updated_at
    }

    CandidateSource {
        bigint id PK
        bigint candidate_id FK
        string source_type
        string source_detail
        bigint source_job_id FK
        datetime created_at
    }

    CandidateCustomFieldValue {
        bigint id PK
        bigint candidate_id FK
        bigint custom_field_id FK
        text value
        datetime created_at
        datetime updated_at
    }
```

## Entities

### Candidate (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| first_name | string | NOT NULL | First name |
| last_name | string | NOT NULL | Last name |
| email | string | NOT NULL, ENCRYPTED | Email address |
| phone | string | NULL, ENCRYPTED | Phone number |
| location | string | NULL | Current location |
| linkedin_url | string | NULL | LinkedIn profile URL |
| portfolio_url | string | NULL | Portfolio/website |
| summary | text | NULL | Professional summary |
| referred_by_id | bigint | FK, NULL | Referring employee |
| agency_id | bigint | FK, NULL | Submitting agency |
| merged_into_id | bigint | FK, NULL | Merged into candidate |
| merged_at | datetime | NULL | Merge timestamp |
| parsed_profile | jsonb | NULL | Aggregated parsed data |
| discarded_at | datetime | NULL | Soft delete |

**Unique Constraint:** `(organization_id, email)` for duplicate detection

### Resume

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| candidate_id | bigint | FK, NOT NULL | Parent candidate |
| filename | string | NOT NULL | Original filename |
| content_type | string | NOT NULL | MIME type |
| file_size | integer | NOT NULL | Size in bytes |
| storage_key | string | NOT NULL | Cloud storage key |
| raw_text | text | NULL | Extracted text |
| parsed_data | jsonb | NULL | Structured parsed data |
| primary | boolean | DEFAULT false | Primary resume flag |
| parsed_at | datetime | NULL | Parse completion time |

**Parsed Data Structure:**
```json
{
  "contact": { "email": "", "phone": "", "location": "" },
  "experience": [
    { "company": "", "title": "", "start": "", "end": "", "description": "" }
  ],
  "education": [
    { "institution": "", "degree": "", "field": "", "year": "" }
  ],
  "skills": ["skill1", "skill2"],
  "certifications": [],
  "languages": []
}
```

### CandidateNote

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| candidate_id | bigint | FK, NOT NULL | Parent candidate |
| user_id | bigint | FK, NOT NULL | Note author |
| content | text | NOT NULL | Note content |
| visibility | enum | DEFAULT 'team' | private, team, all |
| pinned | boolean | DEFAULT false | Pinned to top |

### TalentPool

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| name | string | NOT NULL | Pool name |
| description | text | NULL | Pool description |
| owner_id | bigint | FK, NOT NULL | Pool owner |
| shared | boolean | DEFAULT true | Visible to team |

### Agency

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| name | string | NOT NULL | Agency name |
| contact_email | string | NULL | Primary contact email |
| contact_name | string | NULL | Primary contact name |
| fee_percentage | decimal | NULL | Placement fee % |
| active | boolean | DEFAULT true | Active relationship |

---

# SA-05: Application Pipeline

## Context Overview

Manages the application workflow from submission through hire/rejection. This is the **core domain** that ties jobs and candidates together.

## Aggregate: Application

```mermaid
erDiagram
    Application ||--o{ StageTransition : has
    Application ||--o{ ApplicationCustomFieldValue : has
    Application }o--|| Job : for_job
    Application }o--|| Candidate : for_candidate
    Application }o--|| Stage : current_stage
    Application }o--o| RejectionReason : rejected_with
    StageTransition }o--|| Stage : from_stage
    StageTransition }o--|| Stage : to_stage
    StageTransition }o--o| User : moved_by

    Application {
        bigint id PK
        bigint organization_id FK
        bigint job_id FK
        bigint candidate_id FK
        bigint current_stage_id FK
        string status
        bigint rejection_reason_id FK
        text rejection_notes
        bigint source_id FK
        string source_type
        string source_detail
        datetime applied_at
        datetime hired_at
        datetime rejected_at
        datetime withdrawn_at
        integer rating
        boolean starred
        datetime last_activity_at
        datetime created_at
        datetime updated_at
        datetime discarded_at
    }

    StageTransition {
        bigint id PK
        bigint application_id FK
        bigint from_stage_id FK
        bigint to_stage_id FK
        bigint moved_by_id FK
        text notes
        integer duration_hours
        datetime created_at
    }

    ApplicationCustomFieldValue {
        bigint id PK
        bigint application_id FK
        bigint custom_field_id FK
        text value
        datetime created_at
        datetime updated_at
    }
```

## Entities

### Application (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| job_id | bigint | FK, NOT NULL | Applied job |
| candidate_id | bigint | FK, NOT NULL | Applying candidate |
| current_stage_id | bigint | FK, NOT NULL | Current pipeline stage |
| status | enum | NOT NULL | active, hired, rejected, withdrawn |
| rejection_reason_id | bigint | FK, NULL | Rejection reason |
| rejection_notes | text | NULL | Internal rejection notes |
| source_type | enum | NOT NULL | direct_apply, recruiter, referral, agency, job_board |
| source_detail | string | NULL | Specific source (e.g., "Indeed") |
| applied_at | datetime | NOT NULL | Application timestamp |
| hired_at | datetime | NULL | Hire timestamp |
| rejected_at | datetime | NULL | Rejection timestamp |
| withdrawn_at | datetime | NULL | Withdrawal timestamp |
| rating | integer | NULL | 1-5 recruiter rating |
| starred | boolean | DEFAULT false | Starred/favorited |
| last_activity_at | datetime | NOT NULL | Last action timestamp |
| discarded_at | datetime | NULL | Soft delete |

**Unique Constraint:** `(job_id, candidate_id)` prevents duplicate applications

**Status State Machine:**
```
active → hired
active → rejected
active → withdrawn
```

### StageTransition

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| application_id | bigint | FK, NOT NULL | Parent application |
| from_stage_id | bigint | FK, NULL | Previous stage (null for initial) |
| to_stage_id | bigint | FK, NOT NULL | New stage |
| moved_by_id | bigint | FK, NULL | User who moved (null for system) |
| notes | text | NULL | Transition notes |
| duration_hours | integer | NULL | Hours in previous stage |
| created_at | datetime | NOT NULL | Transition timestamp |

**Immutable:** Stage transitions are never updated or deleted.

---

# SA-06: Interview

## Context Overview

Manages interview scheduling, calendar integration, and participant coordination.

## Aggregate: Interview

```mermaid
erDiagram
    Interview ||--o{ InterviewParticipant : has
    Interview }o--|| Application : for_application
    Interview }o--o| InterviewTemplate : uses
    InterviewParticipant }o--|| User : interviewer
    AvailabilitySlot }o--|| User : for_user
    CalendarConnection }o--|| User : for_user

    Interview {
        bigint id PK
        bigint application_id FK
        bigint interview_template_id FK
        string interview_type
        string title
        text instructions
        datetime scheduled_at
        integer duration_minutes
        string location
        string video_link
        string status
        datetime confirmed_at
        datetime completed_at
        datetime cancelled_at
        string cancellation_reason
        bigint created_by_id FK
        datetime created_at
        datetime updated_at
    }

    InterviewParticipant {
        bigint id PK
        bigint interview_id FK
        bigint user_id FK
        string role
        string response
        string calendar_event_id
        datetime responded_at
        boolean feedback_submitted
        datetime created_at
        datetime updated_at
    }

    InterviewTemplate {
        bigint id PK
        bigint organization_id FK
        string name
        string interview_type
        integer default_duration
        text instructions
        jsonb question_ids
        bigint scorecard_template_id FK
        boolean active
        datetime created_at
        datetime updated_at
    }

    InterviewQuestion {
        bigint id PK
        bigint organization_id FK
        bigint competency_id FK
        text question
        text guidance
        string question_type
        integer position
        boolean active
        datetime created_at
        datetime updated_at
    }

    AvailabilitySlot {
        bigint id PK
        bigint user_id FK
        date date
        time start_time
        time end_time
        boolean recurring
        string recurrence_rule
        datetime created_at
        datetime updated_at
    }

    CalendarConnection {
        bigint id PK
        bigint user_id FK
        string provider
        string external_email
        string access_token_encrypted
        string refresh_token_encrypted
        datetime token_expires_at
        boolean sync_enabled
        datetime last_synced_at
        datetime created_at
        datetime updated_at
    }
```

## Entities

### Interview (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| application_id | bigint | FK, NOT NULL | Parent application |
| interview_template_id | bigint | FK, NULL | Template used |
| interview_type | enum | NOT NULL | phone_screen, video, onsite, panel, take_home |
| title | string | NOT NULL | Interview title |
| instructions | text | NULL | Interview instructions |
| scheduled_at | datetime | NULL | Scheduled time |
| duration_minutes | integer | NOT NULL | Duration |
| location | string | NULL | Physical location |
| video_link | string | NULL | Video conference URL |
| status | enum | NOT NULL | draft, scheduled, confirmed, completed, cancelled, no_show |
| confirmed_at | datetime | NULL | Confirmation timestamp |
| completed_at | datetime | NULL | Completion timestamp |
| cancelled_at | datetime | NULL | Cancellation timestamp |
| cancellation_reason | text | NULL | Why cancelled |
| created_by_id | bigint | FK, NOT NULL | Creator |

### InterviewParticipant

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| interview_id | bigint | FK, NOT NULL | Parent interview |
| user_id | bigint | FK, NOT NULL | Interviewer |
| role | enum | NOT NULL | interviewer, organizer, shadow |
| response | enum | DEFAULT 'pending' | pending, accepted, declined, tentative |
| calendar_event_id | string | NULL | External calendar ID |
| responded_at | datetime | NULL | Response timestamp |
| feedback_submitted | boolean | DEFAULT false | Scorecard submitted |

### InterviewTemplate

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Owning organization |
| name | string | NOT NULL | Template name |
| interview_type | enum | NOT NULL | Interview type |
| default_duration | integer | DEFAULT 60 | Default minutes |
| instructions | text | NULL | Default instructions |
| question_ids | jsonb | NULL | Question references |
| scorecard_template_id | bigint | FK, NULL | Linked scorecard |
| active | boolean | DEFAULT true | Available for use |

---

# SA-07: Evaluation

## Context Overview

Manages interview feedback, scorecards, and hiring decisions.

## Aggregate: Scorecard

```mermaid
erDiagram
    Scorecard ||--o{ ScorecardAttribute : has
    Scorecard }o--|| Interview : for_interview
    Scorecard }o--|| User : submitted_by
    ScorecardAttribute }o--|| Competency : evaluates
    ScorecardTemplate ||--o{ ScorecardTemplateAttribute : defines
    ScorecardTemplateAttribute }o--|| Competency : uses
    HiringDecision }o--|| Application : for_application
    HiringDecision }o--|| User : decided_by

    Scorecard {
        bigint id PK
        bigint interview_id FK
        bigint user_id FK
        bigint scorecard_template_id FK
        string overall_rating
        text recommendation
        text strengths
        text concerns
        boolean hire_recommendation
        datetime submitted_at
        datetime created_at
        datetime updated_at
    }

    ScorecardAttribute {
        bigint id PK
        bigint scorecard_id FK
        bigint competency_id FK
        integer rating
        text notes
        datetime created_at
        datetime updated_at
    }

    ScorecardTemplate {
        bigint id PK
        bigint organization_id FK
        string name
        text instructions
        boolean active
        datetime created_at
        datetime updated_at
    }

    ScorecardTemplateAttribute {
        bigint id PK
        bigint scorecard_template_id FK
        bigint competency_id FK
        integer position
        boolean required
        datetime created_at
    }

    HiringDecision {
        bigint id PK
        bigint application_id FK
        bigint decided_by_id FK
        string decision
        text justification
        datetime decided_at
        datetime created_at
    }
```

## Entities

### Scorecard (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| interview_id | bigint | FK, NOT NULL | Parent interview |
| user_id | bigint | FK, NOT NULL | Submitting interviewer |
| scorecard_template_id | bigint | FK, NULL | Template used |
| overall_rating | enum | NULL | strong_no, no, neutral, yes, strong_yes |
| recommendation | text | NULL | Written recommendation |
| strengths | text | NULL | Candidate strengths |
| concerns | text | NULL | Concerns noted |
| hire_recommendation | boolean | NULL | Explicit hire yes/no |
| submitted_at | datetime | NULL | Submission timestamp |

### ScorecardAttribute

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| scorecard_id | bigint | FK, NOT NULL | Parent scorecard |
| competency_id | bigint | FK, NOT NULL | Evaluated competency |
| rating | integer | NOT NULL | 1-5 rating |
| notes | text | NULL | Attribute notes |

### HiringDecision

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| application_id | bigint | FK, NOT NULL | Application |
| decided_by_id | bigint | FK, NOT NULL | Decision maker |
| decision | enum | NOT NULL | hire, reject, hold |
| justification | text | NOT NULL | Decision rationale |
| decided_at | datetime | NOT NULL | Decision timestamp |

**Immutable:** Decisions are never updated, only new ones added.

---

# SA-08: Offer Management

## Context Overview

Manages offer creation, approval workflows, and e-signature integration.

## Aggregate: Offer

```mermaid
erDiagram
    Offer ||--o{ OfferApproval : requires
    Offer ||--o{ OfferDocument : has
    Offer }o--|| Application : for_application
    Offer }o--|| User : created_by
    Offer }o--o| OfferTemplate : from_template
    OfferApproval }o--|| User : approver
    OfferDocument }o--o| User : signed_by

    Offer {
        bigint id PK
        bigint application_id FK
        bigint created_by_id FK
        bigint offer_template_id FK
        string status
        string title
        integer salary
        string salary_currency
        string salary_period
        integer bonus
        string equity
        date start_date
        date expiration_date
        text notes
        jsonb custom_fields
        datetime sent_at
        datetime viewed_at
        datetime responded_at
        datetime accepted_at
        datetime declined_at
        text decline_reason
        datetime withdrawn_at
        text withdrawal_reason
        datetime created_at
        datetime updated_at
    }

    OfferApproval {
        bigint id PK
        bigint offer_id FK
        bigint approver_id FK
        string status
        text notes
        integer sequence
        datetime decided_at
        datetime created_at
        datetime updated_at
    }

    OfferTemplate {
        bigint id PK
        bigint organization_id FK
        string name
        text body
        jsonb variables
        boolean active
        datetime created_at
        datetime updated_at
    }

    OfferDocument {
        bigint id PK
        bigint offer_id FK
        string document_type
        string filename
        string storage_key
        string status
        bigint signed_by_id FK
        string signature_request_id
        datetime sent_at
        datetime signed_at
        datetime created_at
        datetime updated_at
    }
```

## Entities

### Offer (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| application_id | bigint | FK, NOT NULL | Parent application |
| created_by_id | bigint | FK, NOT NULL | Creator |
| offer_template_id | bigint | FK, NULL | Source template |
| status | enum | NOT NULL | draft, pending_approval, approved, sent, viewed, accepted, declined, withdrawn, expired |
| title | string | NOT NULL | Position title |
| salary | integer | NOT NULL, ENCRYPTED | Base salary (cents) |
| salary_currency | string | DEFAULT 'USD' | Currency |
| salary_period | enum | NOT NULL | hourly, annual |
| bonus | integer | NULL, ENCRYPTED | Sign-on bonus (cents) |
| equity | string | NULL, ENCRYPTED | Equity details |
| start_date | date | NULL | Proposed start date |
| expiration_date | date | NULL | Offer expiration |
| notes | text | NULL | Internal notes |
| custom_fields | jsonb | NULL | Additional fields |
| sent_at | datetime | NULL | When sent to candidate |
| viewed_at | datetime | NULL | When candidate viewed |
| responded_at | datetime | NULL | Candidate response time |
| accepted_at | datetime | NULL | Acceptance time |
| declined_at | datetime | NULL | Decline time |
| decline_reason | text | NULL | Why declined |
| withdrawn_at | datetime | NULL | Withdrawal time |
| withdrawal_reason | text | NULL | Why withdrawn |

**Status State Machine:**
```
draft → pending_approval → approved → sent → viewed → accepted
                                         ↓         ↓
                                      expired   declined
                           ↓
                        withdrawn (from any state except accepted)
```

### OfferApproval

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| offer_id | bigint | FK, NOT NULL | Parent offer |
| approver_id | bigint | FK, NOT NULL | Approver |
| status | enum | NOT NULL | pending, approved, rejected |
| notes | text | NULL | Approval notes |
| sequence | integer | DEFAULT 0 | Approval order |
| decided_at | datetime | NULL | Decision time |

### OfferDocument

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| offer_id | bigint | FK, NOT NULL | Parent offer |
| document_type | enum | NOT NULL | offer_letter, employment_agreement, nda, other |
| filename | string | NOT NULL | Document filename |
| storage_key | string | NOT NULL | Cloud storage key |
| status | enum | NOT NULL | draft, pending_signature, signed, void |
| signed_by_id | bigint | FK, NULL | Signer (user or candidate reference) |
| signature_request_id | string | NULL | External e-sign ID |
| sent_at | datetime | NULL | Sent for signature |
| signed_at | datetime | NULL | Signature timestamp |

---

# SA-09: Compliance & Audit

## Context Overview

Manages regulatory compliance (EEOC, GDPR), background checks, adverse actions, and comprehensive audit logging.

## Aggregate: AuditLog

```mermaid
erDiagram
    AuditLog }o--|| Organization : for_org
    AuditLog }o--o| User : by_user
    EeocResponse }o--|| Candidate : for_candidate
    EeocResponse }o--o| Application : for_application
    Consent }o--|| Candidate : for_candidate
    BackgroundCheck }o--|| Application : for_application
    AdverseAction }o--|| BackgroundCheck : for_check
    DataRetentionPolicy }o--|| Organization : for_org
    DeletionRequest }o--|| Candidate : for_candidate

    AuditLog {
        bigint id PK
        bigint organization_id FK
        bigint user_id FK
        string action
        string auditable_type
        bigint auditable_id
        jsonb metadata
        jsonb changes
        string ip_address
        string user_agent
        string request_id
        datetime created_at
    }

    EeocResponse {
        bigint id PK
        bigint candidate_id FK
        bigint application_id FK
        string gender_encrypted
        string ethnicity_encrypted
        string veteran_status_encrypted
        string disability_status_encrypted
        datetime collected_at
        string collection_method
        datetime created_at
    }

    Consent {
        bigint id PK
        bigint candidate_id FK
        string consent_type
        boolean granted
        string ip_address
        string user_agent
        text consent_text
        datetime granted_at
        datetime revoked_at
        datetime created_at
        datetime updated_at
    }

    BackgroundCheck {
        bigint id PK
        bigint application_id FK
        bigint candidate_id FK
        string provider
        string external_id
        string package
        string status
        jsonb results
        datetime initiated_at
        datetime completed_at
        bigint initiated_by_id FK
        datetime created_at
        datetime updated_at
    }

    AdverseAction {
        bigint id PK
        bigint background_check_id FK
        string status
        text reason
        datetime pre_adverse_sent_at
        datetime pre_adverse_deadline
        datetime final_adverse_sent_at
        text candidate_response
        datetime candidate_responded_at
        bigint initiated_by_id FK
        datetime created_at
        datetime updated_at
    }

    DataRetentionPolicy {
        bigint id PK
        bigint organization_id FK
        string entity_type
        integer retention_days
        string action
        boolean active
        datetime created_at
        datetime updated_at
    }

    DeletionRequest {
        bigint id PK
        bigint candidate_id FK
        string request_source
        string status
        datetime requested_at
        datetime processed_at
        bigint processed_by_id FK
        text notes
        datetime created_at
        datetime updated_at
    }
```

## Entities

### AuditLog (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Organization scope |
| user_id | bigint | FK, NULL | Acting user (null for system) |
| action | string | NOT NULL | Action identifier |
| auditable_type | string | NOT NULL | Entity type |
| auditable_id | bigint | NOT NULL | Entity ID |
| metadata | jsonb | NOT NULL | Action context |
| changes | jsonb | NULL | Before/after values |
| ip_address | string | NULL | Client IP |
| user_agent | string | NULL | Client user agent |
| request_id | string | NULL | Request correlation ID |
| created_at | datetime | NOT NULL | Event timestamp |

**Immutable:** Audit logs are never updated or deleted.

**Action Examples:**
- `job.created`, `job.approved`, `job.closed`
- `application.created`, `application.stage_changed`, `application.rejected`
- `offer.sent`, `offer.accepted`
- `user.login`, `user.password_changed`

### EeocResponse

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| candidate_id | bigint | FK, NOT NULL | Candidate |
| application_id | bigint | FK, NULL | Specific application |
| gender_encrypted | string | ENCRYPTED | Gender response |
| ethnicity_encrypted | string | ENCRYPTED | Ethnicity response |
| veteran_status_encrypted | string | ENCRYPTED | Veteran status |
| disability_status_encrypted | string | ENCRYPTED | Disability status |
| collected_at | datetime | NOT NULL | Collection timestamp |
| collection_method | enum | NOT NULL | career_site, recruiter_entry |

**Access Control:** Only compliance roles can decrypt individual records. Reports use aggregate queries only.

### Consent

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| candidate_id | bigint | FK, NOT NULL | Candidate |
| consent_type | enum | NOT NULL | data_processing, marketing, background_check |
| granted | boolean | NOT NULL | Consent given |
| ip_address | string | NULL | Consent IP |
| user_agent | string | NULL | Consent user agent |
| consent_text | text | NOT NULL | Text presented |
| granted_at | datetime | NULL | Grant timestamp |
| revoked_at | datetime | NULL | Revocation timestamp |

### BackgroundCheck

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| application_id | bigint | FK, NOT NULL | Application |
| candidate_id | bigint | FK, NOT NULL | Candidate |
| provider | string | NOT NULL | ledgoria, checkr, sterling |
| external_id | string | NULL | Provider's ID |
| package | string | NOT NULL | Check package name |
| status | enum | NOT NULL | pending, in_progress, completed, cancelled, error |
| results | jsonb | NULL | Check results |
| initiated_at | datetime | NOT NULL | Start time |
| completed_at | datetime | NULL | Completion time |
| initiated_by_id | bigint | FK, NOT NULL | Initiator |

### AdverseAction

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| background_check_id | bigint | FK, NOT NULL | Related check |
| status | enum | NOT NULL | pending, pre_adverse_sent, waiting_period, final_sent, cancelled |
| reason | text | NOT NULL | Adverse action reason |
| pre_adverse_sent_at | datetime | NULL | Pre-adverse notice sent |
| pre_adverse_deadline | datetime | NULL | Response deadline |
| final_adverse_sent_at | datetime | NULL | Final notice sent |
| candidate_response | text | NULL | Candidate response |
| candidate_responded_at | datetime | NULL | Response time |
| initiated_by_id | bigint | FK, NOT NULL | Initiator |

---

# SA-10: Communication

## Context Overview

Manages email templates, notifications, SMS, and communication tracking.

## Aggregate: EmailLog

```mermaid
erDiagram
    EmailTemplate }o--|| Organization : for_org
    EmailLog }o--|| Organization : for_org
    EmailLog }o--o| EmailTemplate : from_template
    EmailSequence ||--o{ EmailSequenceStep : has
    EmailSequenceEnrollment }o--|| EmailSequence : in_sequence
    EmailSequenceEnrollment }o--|| Candidate : for_candidate
    Notification }o--|| User : for_user
    SmsLog }o--|| Candidate : to_candidate

    EmailTemplate {
        bigint id PK
        bigint organization_id FK
        string name
        string subject
        text body
        string template_type
        jsonb variables
        boolean active
        datetime created_at
        datetime updated_at
    }

    EmailLog {
        bigint id PK
        bigint organization_id FK
        bigint email_template_id FK
        string recipient_type
        bigint recipient_id
        string recipient_email
        string subject
        text body
        string status
        datetime queued_at
        datetime sent_at
        datetime delivered_at
        datetime opened_at
        datetime clicked_at
        datetime bounced_at
        datetime unsubscribed_at
        string message_id
        jsonb metadata
        datetime created_at
        datetime updated_at
    }

    EmailSequence {
        bigint id PK
        bigint organization_id FK
        string name
        string trigger_event
        boolean active
        datetime created_at
        datetime updated_at
    }

    EmailSequenceStep {
        bigint id PK
        bigint email_sequence_id FK
        bigint email_template_id FK
        integer delay_days
        integer delay_hours
        integer position
        datetime created_at
        datetime updated_at
    }

    EmailSequenceEnrollment {
        bigint id PK
        bigint email_sequence_id FK
        bigint candidate_id FK
        bigint application_id FK
        string status
        integer current_step
        datetime enrolled_at
        datetime completed_at
        datetime unsubscribed_at
        datetime created_at
        datetime updated_at
    }

    Notification {
        bigint id PK
        bigint user_id FK
        string notification_type
        string title
        text body
        string link
        boolean read
        datetime read_at
        datetime created_at
    }

    SmsLog {
        bigint id PK
        bigint organization_id FK
        bigint candidate_id FK
        string phone_number
        text message
        string status
        string external_id
        datetime sent_at
        datetime delivered_at
        datetime failed_at
        string failure_reason
        datetime created_at
    }
```

## Entities

### EmailTemplate

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Organization |
| name | string | NOT NULL | Template name |
| subject | string | NOT NULL | Email subject |
| body | text | NOT NULL | Email body (Liquid/ERB) |
| template_type | enum | NOT NULL | application_received, interview_scheduled, offer_sent, rejection, custom |
| variables | jsonb | NULL | Available variables |
| active | boolean | DEFAULT true | Available for use |

### EmailLog (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Organization |
| email_template_id | bigint | FK, NULL | Source template |
| recipient_type | string | NOT NULL | Candidate, User |
| recipient_id | bigint | NOT NULL | Recipient ID |
| recipient_email | string | NOT NULL | Actual email |
| subject | string | NOT NULL | Rendered subject |
| body | text | NOT NULL | Rendered body |
| status | enum | NOT NULL | queued, sent, delivered, opened, clicked, bounced, failed |
| queued_at | datetime | NULL | Queue time |
| sent_at | datetime | NULL | Send time |
| delivered_at | datetime | NULL | Delivery confirmation |
| opened_at | datetime | NULL | First open |
| clicked_at | datetime | NULL | First click |
| bounced_at | datetime | NULL | Bounce time |
| unsubscribed_at | datetime | NULL | Unsubscribe time |
| message_id | string | NULL | ESP message ID |
| metadata | jsonb | NULL | Additional data |

### Notification

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| user_id | bigint | FK, NOT NULL | Recipient user |
| notification_type | string | NOT NULL | Type identifier |
| title | string | NOT NULL | Notification title |
| body | text | NULL | Notification body |
| link | string | NULL | Action URL |
| read | boolean | DEFAULT false | Read status |
| read_at | datetime | NULL | Read timestamp |

---

# SA-11: Integration

## Context Overview

Manages external system integrations including job boards, HRIS, calendar, and API access.

## Aggregate: IntegrationConfig

```mermaid
erDiagram
    IntegrationConfig }o--|| Organization : for_org
    IntegrationLog }o--|| IntegrationConfig : for_integration
    Webhook }o--|| Organization : for_org
    WebhookDelivery }o--|| Webhook : for_webhook
    HrisExport }o--|| Application : for_application

    IntegrationConfig {
        bigint id PK
        bigint organization_id FK
        string integration_type
        string provider
        jsonb credentials_encrypted
        jsonb settings
        boolean enabled
        datetime last_sync_at
        string sync_status
        datetime created_at
        datetime updated_at
    }

    IntegrationLog {
        bigint id PK
        bigint integration_config_id FK
        string action
        string status
        string direction
        jsonb request_data
        jsonb response_data
        string error_message
        integer duration_ms
        datetime created_at
    }

    Webhook {
        bigint id PK
        bigint organization_id FK
        string name
        string url
        string secret
        jsonb events
        boolean enabled
        datetime created_at
        datetime updated_at
    }

    WebhookDelivery {
        bigint id PK
        bigint webhook_id FK
        string event_type
        jsonb payload
        integer response_code
        text response_body
        integer attempts
        datetime last_attempt_at
        datetime delivered_at
        datetime created_at
    }

    HrisExport {
        bigint id PK
        bigint application_id FK
        bigint integration_config_id FK
        string status
        string external_id
        jsonb exported_data
        datetime exported_at
        string error_message
        datetime created_at
        datetime updated_at
    }
```

## Entities

### IntegrationConfig (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Organization |
| integration_type | enum | NOT NULL | job_board, hris, calendar, background_check, sso |
| provider | string | NOT NULL | indeed, linkedin, workday, google, etc. |
| credentials_encrypted | jsonb | ENCRYPTED | API credentials |
| settings | jsonb | NULL | Provider settings |
| enabled | boolean | DEFAULT true | Active flag |
| last_sync_at | datetime | NULL | Last sync |
| sync_status | enum | NULL | success, error, pending |

### IntegrationLog

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| integration_config_id | bigint | FK, NOT NULL | Parent config |
| action | string | NOT NULL | Action performed |
| status | enum | NOT NULL | success, error |
| direction | enum | NOT NULL | inbound, outbound |
| request_data | jsonb | NULL | Request payload |
| response_data | jsonb | NULL | Response payload |
| error_message | string | NULL | Error details |
| duration_ms | integer | NULL | Request duration |

### Webhook

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Organization |
| name | string | NOT NULL | Webhook name |
| url | string | NOT NULL | Destination URL |
| secret | string | NOT NULL | Signing secret |
| events | jsonb | NOT NULL | Subscribed events |
| enabled | boolean | DEFAULT true | Active flag |

### WebhookDelivery

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| webhook_id | bigint | FK, NOT NULL | Parent webhook |
| event_type | string | NOT NULL | Event name |
| payload | jsonb | NOT NULL | Event payload |
| response_code | integer | NULL | HTTP response code |
| response_body | text | NULL | Response body |
| attempts | integer | DEFAULT 0 | Delivery attempts |
| last_attempt_at | datetime | NULL | Last attempt |
| delivered_at | datetime | NULL | Success timestamp |

---

# SA-12: Career Site

## Context Overview

Manages the public-facing career site, branding, and candidate application experience.

## Aggregate: CareerSiteConfig

```mermaid
erDiagram
    CareerSiteConfig }o--|| Organization : for_org
    CareerSitePage }o--|| CareerSiteConfig : has
    ApplicationQuestion }o--|| Job : for_job

    CareerSiteConfig {
        bigint id PK
        bigint organization_id FK
        string site_title
        text site_description
        string primary_color
        string secondary_color
        string logo_url
        string favicon_url
        string custom_css
        string custom_js
        jsonb social_links
        jsonb seo_settings
        boolean enabled
        datetime created_at
        datetime updated_at
    }

    CareerSitePage {
        bigint id PK
        bigint career_site_config_id FK
        string page_type
        string title
        string slug
        text content
        integer position
        boolean published
        datetime created_at
        datetime updated_at
    }

    ApplicationQuestion {
        bigint id PK
        bigint job_id FK
        string question_type
        string label
        text description
        jsonb options
        boolean required
        integer position
        datetime created_at
        datetime updated_at
    }
```

## Entities

### CareerSiteConfig (Aggregate Root)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| organization_id | bigint | FK, NOT NULL | Organization |
| site_title | string | NOT NULL | Site title |
| site_description | text | NULL | SEO description |
| primary_color | string | DEFAULT '#000000' | Primary brand color |
| secondary_color | string | DEFAULT '#ffffff' | Secondary color |
| logo_url | string | NULL | Logo image |
| favicon_url | string | NULL | Favicon |
| custom_css | text | NULL | Custom styles |
| custom_js | text | NULL | Custom scripts |
| social_links | jsonb | NULL | Social media links |
| seo_settings | jsonb | NULL | SEO configuration |
| enabled | boolean | DEFAULT true | Site active |

### CareerSitePage

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| career_site_config_id | bigint | FK, NOT NULL | Parent config |
| page_type | enum | NOT NULL | home, about, benefits, custom |
| title | string | NOT NULL | Page title |
| slug | string | NOT NULL | URL slug |
| content | text | NOT NULL | Page content |
| position | integer | DEFAULT 0 | Navigation order |
| published | boolean | DEFAULT false | Published flag |

### ApplicationQuestion

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | bigint | PK | Unique identifier |
| job_id | bigint | FK, NOT NULL | Parent job |
| question_type | enum | NOT NULL | text, textarea, select, multiselect, boolean, file |
| label | string | NOT NULL | Question label |
| description | text | NULL | Help text |
| options | jsonb | NULL | Select options |
| required | boolean | DEFAULT false | Required flag |
| position | integer | DEFAULT 0 | Question order |

---

# Cross-Context Integration Points

## Domain Events

Events published by each context for consumption by others:

| Context | Event | Consumers | Description |
|---------|-------|-----------|-------------|
| Job | `job.opened` | Integration, Career Site | Job ready for applications |
| Job | `job.closed` | Integration, Communication | Job no longer accepting |
| Application | `application.created` | Communication, Compliance | New application received |
| Application | `application.stage_changed` | Communication | Pipeline movement |
| Application | `application.rejected` | Communication, Compliance | Candidate rejected |
| Application | `application.hired` | Communication, Integration, Compliance | Candidate hired |
| Interview | `interview.scheduled` | Communication | Interview booked |
| Interview | `interview.completed` | Evaluation | Interview done |
| Offer | `offer.sent` | Communication | Offer delivered |
| Offer | `offer.accepted` | Application, Integration | Offer accepted |
| BackgroundCheck | `check.completed` | Application, Compliance | Results received |

## Shared Kernel

Common entities referenced across contexts:

| Entity | Owning Context | Consuming Contexts |
|--------|----------------|-------------------|
| Organization | Organization | All |
| User | Identity & Access | All |
| Stage | Organization | Application, Job |
| Competency | Organization | Evaluation, Interview |
| RejectionReason | Organization | Application |

---

# Implementation Notes

## Multi-tenancy Strategy

- All tables include `organization_id`
- Application-level enforcement via `Current.organization`
- Database indexes include `organization_id` prefix
- Consider row-level security for additional protection

## Encryption Strategy

Use Rails 7+ `encrypts` for:
- Candidate PII: email, phone
- Financial: salary, bonus, equity
- Compliance: EEOC responses
- Integration: API credentials

## Soft Deletes

Use `discarded_at` for:
- Organization
- Job
- Candidate
- Application

## Immutable Records

Never update:
- AuditLog
- StageTransition
- HiringDecision
- Consent

## Service Extraction Path

When extracting services, each subject area maps to a bounded context:

1. **Phase 1 (Monolith):** All contexts in single Rails app
2. **Phase 2 (Modular Monolith):** Separate engines/namespaces
3. **Phase 3 (Services):** Extract high-value contexts
   - Communication → Email service
   - Integration → Integration gateway
   - Compliance → Audit service

Recommended extraction order:
1. Communication (high volume, independent)
2. Integration (external dependencies)
3. Compliance (regulatory requirements)
