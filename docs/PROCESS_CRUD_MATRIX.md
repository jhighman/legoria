# Ledgoria - Process CRUD Matrix

## Overview

This document maps each **Elementary Business Process (EBP)** from the [PROCESS_MODEL.md](PROCESS_MODEL.md) to the database operations (Create, Read, Update, Delete) it performs on each entity. This matrix enables:

- **Entity Affinity Analysis** - Identify which processes share entity access
- **Bounded Context Validation** - Verify subject area boundaries
- **System Partitioning** - Guide microservice extraction decisions
- **Transaction Design** - Plan database transaction boundaries

## Legend

| Symbol | Meaning |
|--------|---------|
| **C** | Create - INSERT new record |
| **R** | Read - SELECT existing record |
| **U** | Update - UPDATE existing record |
| **D** | Delete - DELETE record (soft or hard) |
| **-** | No interaction with this entity |
| **(C)** | Conditional Create |
| **(U)** | Conditional Update |
| **(D)** | Conditional Delete (soft delete) |

---

# BF-01: Talent Acquisition

## BP-101: Requisition Management

| Elementary Process | Job | JobStage | JobApproval | JobBoardPosting | Department | User | Stage | AuditLog |
|--------------------|-----|----------|-------------|-----------------|------------|------|-------|----------|
| EP-0101: Create Requisition | C | C | (C) | - | R | R | R | C |
| EP-0102: Edit Requisition | U | - | - | - | R | R | - | C |
| EP-0103: Submit for Approval | U | - | C | - | - | R | - | C |
| EP-0104: Approve Requisition | U | - | U | - | - | R | - | C |
| EP-0105: Reject Requisition | U | - | U | - | - | R | - | C |
| EP-0106: Open Job | U | - | - | - | - | R | - | C |
| EP-0107: Put Job On Hold | U | - | - | - | - | R | - | C |
| EP-0108: Close Job | U | - | - | - | - | R | - | C |
| EP-0109: Clone Job | C | C | - | - | R | R | R | C |
| EP-0110: Configure Stages | R | CUD | - | - | - | R | R | C |
| EP-0111: Post to Boards | U | - | - | C | - | R | - | C |
| EP-0112: Remove from Boards | U | - | - | D | - | R | - | C |

### Entity Affinity Clusters

**Primary Cluster:** Job, JobStage, JobApproval
- Tightly coupled: all requisition management processes access these together
- Transaction boundary: Job creation includes JobStage copies

**Secondary Cluster:** JobBoardPosting
- Loosely coupled: only posting processes access this
- Could be extracted to integration service

---

## BP-102: Candidate Sourcing

| Elementary Process | Candidate | Resume | CandidateNote | CandidateTag | Tag | TalentPool | TalentPoolMember | Agency | AuditLog |
|--------------------|-----------|--------|---------------|--------------|-----|------------|------------------|--------|----------|
| EP-0201: Add Candidate | C | (C) | - | - | - | - | - | - | C |
| EP-0202: Import Candidates | C | (C) | - | - | - | - | - | - | C |
| EP-0203: Submit Referral | C | (C) | - | - | - | - | - | - | C |
| EP-0204: Agency Submission | C | (C) | - | - | - | - | - | R | C |
| EP-0205: Edit Candidate | U | - | - | - | - | - | - | - | C |
| EP-0206: Upload Resume | (U) | C | - | - | - | - | - | - | C |
| EP-0207: Parse Resume | U | U | - | - | - | - | - | - | C |
| EP-0208: Add Candidate Note | R | - | C | - | - | - | - | - | C |
| EP-0209: Tag Candidate | U | - | - | CUD | R | - | - | - | C |
| EP-0210: Detect Duplicates | R | - | - | - | - | - | - | - | - |
| EP-0211: Merge Candidates | U | (U) | (C) | (U) | - | - | - | - | C |

### Entity Affinity Clusters

**Primary Cluster:** Candidate, Resume
- Tightly coupled: candidate operations typically involve resume handling
- Transaction boundary: candidate creation with resume attachment

**Secondary Cluster:** CandidateNote, CandidateTag, Tag
- Supplementary data: tagging and notes are auxiliary operations
- Could operate independently with eventual consistency

---

## BP-103: Application Processing

| Elementary Process | Application | StageTransition | Candidate | Resume | Consent | CustomFieldResponse | Job | Stage | AuditLog |
|--------------------|-------------|-----------------|-----------|--------|---------|---------------------|-----|-------|----------|
| EP-0301: Apply for Job | C | C | CU | C | C | (C) | R | R | C |
| EP-0302: Add to Job | C | C | R | - | - | - | R | R | C |
| EP-0303: View Pipeline | R | R | R | R | - | R | R | R | - |

### Entity Affinity Clusters

**Primary Cluster:** Application, StageTransition, Candidate
- Core workflow: application processing always touches these together
- Transaction boundary: application creation with stage transition

---

## BP-104: Pipeline Management

| Elementary Process | Application | StageTransition | RejectionReason | Stage | Job | AuditLog |
|--------------------|-------------|-----------------|-----------------|-------|-----|----------|
| EP-0401: Move Stage | U | C | - | R | R | C |
| EP-0402: Bulk Move Stage | U | C | - | R | R | C |
| EP-0403: Reject Candidate | U | C | R | R | R | C |
| EP-0404: Bulk Reject | U | C | R | R | R | C |
| EP-0405: Withdraw Application | U | C | - | R | R | C |
| EP-0406: Reopen Application | U | C | - | R | R | C |
| EP-0407: View History | R | R | R | R | R | R |
| EP-0408: Transfer Job | U | C | - | R | R | C |

### Entity Affinity Clusters

**Primary Cluster:** Application, StageTransition
- Every pipeline operation creates immutable transition records
- Transaction boundary: application update with transition creation

---

# BF-02: Candidate Evaluation

## BP-201: Interview Coordination

| Elementary Process | Interview | InterviewParticipant | InterviewTemplate | InterviewQuestion | Application | CalendarConnection | AvailabilitySlot | AuditLog |
|--------------------|-----------|---------------------|-------------------|-------------------|-------------|-------------------|------------------|----------|
| EP-0501: Schedule Interview | C | C | R | - | R | - | - | C |
| EP-0502: Create Panel | C | C | R | - | R | - | - | C |
| EP-0503: Send Calendar Invite | R | R | - | - | R | C | - | C |
| EP-0504: Self-Schedule | C | C | - | - | R | C | R | C |
| EP-0505: Reschedule Interview | U | U | - | - | R | U | - | C |
| EP-0506: Cancel Interview | U | U | - | - | R | D | - | C |
| EP-0507: Confirm Attendance | R | U | - | - | - | - | - | C |
| EP-0508: Mark No-Show | U | - | - | - | R | - | - | C |
| EP-0509: Complete Interview | U | R | - | - | U | - | - | C |
| EP-0510: View Interview Kit | R | R | R | R | R | - | - | - |
| EP-0511: Manage Templates | - | - | CUD | CUD | - | - | - | C |

### Entity Affinity Clusters

**Primary Cluster:** Interview, InterviewParticipant
- Tightly coupled: interview operations always involve participants
- Transaction boundary: interview creation with participants

**Secondary Cluster:** InterviewTemplate, InterviewQuestion
- Configuration data: managed separately from active interviews
- Could be cached/read-only in interview context

---

## BP-202: Feedback Collection

| Elementary Process | Scorecard | ScorecardAttribute | Interview | Application | Competency | ScorecardTemplate | EmailLog | AuditLog |
|--------------------|-----------|-------------------|-----------|-------------|------------|-------------------|----------|----------|
| EP-0601: Submit Scorecard | C | C | R | R | R | R | - | C |
| EP-0602: Rate Competencies | U | CU | R | R | R | R | - | C |
| EP-0603: Add Interview Notes | U | - | R | R | - | - | - | C |
| EP-0604: View Team Feedback | R | R | R | R | R | - | - | - |
| EP-0605: Request Feedback | R | - | R | R | - | - | C | C |

### Entity Affinity Clusters

**Primary Cluster:** Scorecard, ScorecardAttribute
- Tightly coupled: scorecard operations always involve attribute ratings
- Transaction boundary: scorecard submission with attributes

---

## BP-203: Hiring Decision Making

| Elementary Process | Application | HiringDecision | Scorecard | StageApproval | Competency | ScorecardTemplate | AuditLog |
|--------------------|-------------|----------------|-----------|---------------|------------|-------------------|----------|
| EP-0701: Make Hiring Decision | U | C | R | - | - | - | C |
| EP-0702: Approve Stage Progression | U | - | R | CU | - | - | C |
| EP-0703: Manage Competencies | - | - | - | - | CUD | - | C |
| EP-0704: Create Scorecard Template | - | - | - | - | R | CUD | C |

---

# BF-03: Offer & Onboarding

## BP-301 to BP-304: Offer Management

| Elementary Process | Offer | OfferApproval | OfferDocument | OfferTemplate | Application | EmailLog | StageTransition | AuditLog |
|--------------------|-------|---------------|---------------|---------------|-------------|----------|-----------------|----------|
| EP-0801: Create Offer | C | - | - | R | R | - | - | C |
| EP-0802: Edit Offer | U | - | - | R | R | - | - | C |
| EP-0811: Submit for Approval | U | C | - | - | R | - | - | C |
| EP-0812: Approve Offer | U | U | - | - | R | - | - | C |
| EP-0813: Reject Offer | U | U | - | - | R | - | - | C |
| EP-0821: Send Offer | U | - | C | R | R | C | - | C |
| EP-0822: Accept Offer | U | - | - | - | U | - | C | C |
| EP-0823: Decline Offer | U | - | - | - | U | - | C | C |
| EP-0824: Negotiate Offer | U | - | - | - | R | - | - | C |
| EP-0825: Withdraw Offer | U | - | - | - | U | C | C | C |
| EP-0831: Mark as Hired | R | - | - | - | U | - | C | C |
| EP-0832: Manage Templates | - | - | - | CUD | - | - | - | C |

### Entity Affinity Clusters

**Primary Cluster:** Offer, OfferApproval, Application
- Tightly coupled: offer workflow operates on these together
- Transaction boundary: offer state changes with application updates

---

# BF-04: Compliance Management

## BP-401 to BP-404: Compliance Operations

| Elementary Process | EeocResponse | Consent | BackgroundCheck | AdverseAction | AuditLog | DataRetentionPolicy | DeletionRequest | Candidate | Application |
|--------------------|--------------|---------|-----------------|---------------|----------|---------------------|-----------------|-----------|-------------|
| EP-0901: Collect EEOC | C | - | - | - | C | - | - | R | R |
| EP-0902: Generate EEOC Report | R | - | - | - | R | - | - | R | R |
| EP-0911: Record Consent | - | C | - | - | C | - | - | R | - |
| EP-0912: Process Deletion | - | R | - | - | C | R | U | (D) | (D) |
| EP-0913: Configure Retention | - | - | - | - | C | CUD | - | - | - |
| EP-0921: Initiate BGC | - | R | C | - | C | - | - | R | R |
| EP-0922: Receive BGC Results | - | - | U | - | C | - | - | R | U |
| EP-0923: Initiate Adverse | - | - | R | C | C | - | - | R | R |
| EP-0924: Complete Adverse | - | - | R | U | C | - | - | R | U |
| EP-0931: View Audit Trail | - | R | R | R | R | - | - | R | R |
| EP-0932: Export Audit Logs | - | R | R | R | R | - | - | R | R |
| EP-0933: Document Decision | - | - | - | - | C | - | - | - | R |

### Entity Affinity Clusters

**Primary Cluster:** BackgroundCheck, AdverseAction
- Tightly coupled: adverse action flows from background check results
- Transaction boundary: adverse action state changes

**Secondary Cluster:** EeocResponse, Consent
- Independent: compliance data collected separately
- Must maintain strict access controls

---

# BF-05: Communication Management

## BP-501 to BP-503: Communications

| Elementary Process | EmailLog | SmsLog | Notification | EmailTemplate | EmailSequence | EmailSequenceStep | NotificationPreference | Candidate | Application | AuditLog |
|--------------------|----------|--------|--------------|---------------|---------------|-------------------|------------------------|-----------|-------------|----------|
| EP-1001: Send Email | C | - | - | R | - | - | - | R | R | C |
| EP-1002: Send Bulk Email | C | - | - | R | - | - | - | R | R | C |
| EP-1003: Schedule Email | C | - | - | R | - | - | - | R | R | C |
| EP-1004: Send SMS | - | C | - | - | - | - | - | R | R | C |
| EP-1005: View Email History | R | R | - | R | - | - | - | R | R | - |
| EP-1011: Send In-App Notification | - | - | C | - | - | - | R | R | - | - |
| EP-1012: Manage Notification Prefs | - | - | R | - | - | - | CU | R | - | C |
| EP-1021: Create Email Sequence | - | - | - | R | CUD | CUD | - | - | - | C |
| EP-1022: Track Email Engagement | RU | RU | - | - | - | - | - | R | R | - |

---

# BF-06: System Administration

## BP-601: User Administration

| Elementary Process | User | UserRole | Role | Organization | AuditLog |
|--------------------|------|----------|------|--------------|----------|
| EP-1101: Create User | C | C | R | R | C |
| EP-1102: Edit User | U | - | R | R | C |
| EP-1103: Deactivate User | U | - | - | R | C |
| EP-1104: Assign Role | U | CUD | R | R | C |

---

## BP-602: Organization Configuration

| Elementary Process | Department | OrganizationSetting | RejectionReason | EmailTemplate | CustomField | Organization | AuditLog |
|--------------------|------------|---------------------|-----------------|---------------|-------------|--------------|----------|
| EP-1111: Manage Departments | CUD | - | - | - | - | R | C |
| EP-1112: Configure Org Settings | - | RU | - | - | - | RU | C |
| EP-1113: Manage Rejection Reasons | - | - | CUD | - | - | R | C |
| EP-1114: Configure Email Templates | - | - | - | CUD | - | R | C |
| EP-1115: View System Health | - | R | - | - | - | R | R |
| EP-1116: Manage Custom Fields | - | - | - | - | CUD | R | C |

---

## BP-603: Integration Management

| Elementary Process | IntegrationConfig | IntegrationLog | JobBoardPosting | HrisExport | CalendarConnection | SsoConfig | ApiKey | Webhook | WebhookDelivery | AuditLog |
|--------------------|-------------------|----------------|-----------------|------------|-------------------|-----------|--------|---------|-----------------|----------|
| EP-1121: Configure Job Board | CUD | - | - | - | - | - | - | - | - | C |
| EP-1122: Sync Jobs to Boards | R | C | CU | - | - | - | - | - | - | C |
| EP-1123: Import Apps from Boards | R | C | - | - | - | - | - | - | - | C |
| EP-1124: Configure HRIS | CUD | - | - | - | - | - | - | - | - | C |
| EP-1125: Export Hire to HRIS | R | C | - | C | - | - | - | - | - | C |
| EP-1126: Configure Calendar | - | - | - | - | CUD | - | - | - | - | C |
| EP-1127: Sync Calendar Events | - | C | - | - | R | - | - | - | - | C |
| EP-1128: Configure SSO | - | - | - | - | - | CUD | - | - | - | C |
| EP-1129: Manage API Keys | - | - | - | - | - | - | CUD | - | R | C |
| EP-1130: Configure Webhooks | - | - | - | - | - | - | - | CUD | R | C |
| EP-1131: View Integration Logs | R | R | - | - | - | - | R | R | R | - |

---

## BP-604: Career Site Management

| Elementary Process | CareerSiteConfig | CareerSitePage | ApplicationQuestion | Job | Candidate | Application | Resume | Consent | CandidateAccount | AuditLog |
|--------------------|------------------|----------------|---------------------|-----|-----------|-------------|--------|---------|------------------|----------|
| EP-1141: Browse Jobs | R | R | - | R | - | - | - | - | - | - |
| EP-1142: Search Jobs | R | - | - | R | - | - | - | - | - | - |
| EP-1143: View Job Details | R | - | - | R | - | - | - | - | - | - |
| EP-1144: Apply for Job | R | - | R | R | CU | C | C | C | - | C |
| EP-1145: Create Candidate Account | R | - | - | - | C | - | - | C | C | C |
| EP-1146: Check Application Status | R | - | - | R | R | R | - | - | R | - |
| EP-1147: Update Profile | R | - | - | - | U | - | - | - | U | C |
| EP-1148: Upload Documents | R | - | - | R | R | R | C | - | - | C |
| EP-1149: Configure Career Site | CU | CUD | - | - | - | - | - | - | - | C |
| EP-1150: Customize Branding | CU | - | - | - | - | - | - | - | - | C |
| EP-1151: Set App Questions | R | - | CUD | R | - | - | - | - | - | C |

---

# BF-07: Analytics & Reporting

## BP-701 to BP-703: Reporting

| Elementary Process | ReportSnapshot | ScheduledReport | Job | Application | Candidate | StageTransition | Offer | EeocResponse | AuditLog |
|--------------------|----------------|-----------------|-----|-------------|-----------|-----------------|-------|--------------|----------|
| EP-1201: View Dashboard | (C) | - | R | R | R | R | R | - | R |
| EP-1202: Time-to-Hire Report | (C) | - | R | R | R | R | - | - | - |
| EP-1203: Source Effectiveness | (C) | - | R | R | R | R | - | - | - |
| EP-1204: Pipeline Conversion | (C) | - | R | R | R | R | - | - | - |
| EP-1205: Recruiter Activity | (C) | - | R | R | R | R | R | - | R |
| EP-1206: Open Requisitions | (C) | - | R | R | R | - | - | - | - |
| EP-1207: Offer Acceptance | (C) | - | R | R | R | - | R | - | - |
| EP-1208: Schedule Report | - | CUD | - | - | - | - | - | - | - |
| EP-1209: Export Report Data | - | R | R | R | R | R | R | - | R |
| EP-1211: Diversity Report | (C) | - | R | R | R | - | - | R | - |
| EP-1221: Executive Dashboard | (C) | - | R | R | R | R | R | R | R |

---

# Entity Affinity Summary

## High-Affinity Entity Clusters

These entity groups are frequently accessed together and should remain in the same bounded context:

### Cluster 1: Application Core
| Entity | Primary Accessor |
|--------|------------------|
| Application | BP-103, BP-104 |
| StageTransition | BP-103, BP-104 |
| Candidate | BP-102, BP-103 |

**Recommendation:** Keep in single Application/Pipeline service

### Cluster 2: Requisition Core
| Entity | Primary Accessor |
|--------|------------------|
| Job | BP-101 |
| JobStage | BP-101 |
| JobApproval | BP-101 |

**Recommendation:** Keep in single Requisition service

### Cluster 3: Interview & Evaluation
| Entity | Primary Accessor |
|--------|------------------|
| Interview | BP-201 |
| InterviewParticipant | BP-201 |
| Scorecard | BP-202 |
| ScorecardAttribute | BP-202 |

**Recommendation:** Keep in single Interview/Evaluation service

### Cluster 4: Offer Workflow
| Entity | Primary Accessor |
|--------|------------------|
| Offer | BP-301, BP-302, BP-303 |
| OfferApproval | BP-302 |
| OfferDocument | BP-303 |

**Recommendation:** Keep in single Offer service

### Cluster 5: Compliance
| Entity | Primary Accessor |
|--------|------------------|
| EeocResponse | BP-401 |
| BackgroundCheck | BP-403 |
| AdverseAction | BP-403 |
| Consent | BP-402 |

**Recommendation:** Keep in single Compliance service with strict access controls

---

## Cross-Cluster Dependencies

| From Cluster | To Cluster | Relationship | Integration Pattern |
|--------------|------------|--------------|---------------------|
| Application | Requisition | Application references Job | Foreign key |
| Application | Candidate | Application references Candidate | Foreign key |
| Interview | Application | Interview references Application | Foreign key |
| Offer | Application | Offer references Application | Foreign key |
| Compliance | Application | EEOC references Application | Foreign key |
| Compliance | Candidate | Consent references Candidate | Foreign key |

---

## High-Write Entities

Entities with highest write frequency (optimize for write performance):

| Entity | Primary Write Operations | Estimated Volume |
|--------|-------------------------|------------------|
| AuditLog | Every user action | Very High |
| Application | Pipeline movements | High |
| StageTransition | Every stage change | High |
| EmailLog | All communications | High |
| Notification | User events | Medium |

---

## Read-Heavy Entities

Entities with high read:write ratio (cache candidates):

| Entity | Primary Read Operations | Caching Strategy |
|--------|------------------------|------------------|
| Stage | Pipeline display | Per-org cache |
| RejectionReason | Rejection modal | Per-org cache |
| EmailTemplate | Email sending | Per-org cache |
| Competency | Scorecard forms | Per-org cache |
| InterviewTemplate | Interview kit | Per-org cache |

---

# System Partitioning Recommendations

Based on the entity affinity analysis, the following service boundaries are recommended for future extraction:

## Phase 1: Modular Monolith (Current)
All contexts in single Rails application with namespace separation.

## Phase 2: Service Extraction Candidates

### Communication Service (High Priority)
- **Entities:** EmailLog, SmsLog, Notification, EmailSequence
- **Processes:** BP-501, BP-502, BP-503
- **Rationale:** High volume, independent operation, clear boundary

### Integration Gateway (High Priority)
- **Entities:** IntegrationConfig, IntegrationLog, JobBoardPosting, HrisExport
- **Processes:** BP-603
- **Rationale:** External dependencies, rate limiting needs, isolation benefits

### Compliance Service (Medium Priority)
- **Entities:** EeocResponse, Consent, BackgroundCheck, AdverseAction, DeletionRequest
- **Processes:** BP-401, BP-402, BP-403, BP-404
- **Rationale:** Regulatory requirements, access control, audit needs

### Analytics Service (Medium Priority)
- **Entities:** ReportSnapshot, ScheduledReport
- **Processes:** BP-701, BP-702, BP-703
- **Rationale:** Read-heavy, different scaling needs, query optimization

---

# Related Documentation

- [PROCESS_MODEL.md](PROCESS_MODEL.md) - Process hierarchy definitions
- [DATA_MODEL.md](DATA_MODEL.md) - Entity definitions and relationships
- [CRUD_MATRIX.md](CRUD_MATRIX.md) - Use case to entity mapping
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture decisions
