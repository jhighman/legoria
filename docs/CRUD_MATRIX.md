# Ledgoria - CRUD Matrix

## Overview

This document maps each use case to the database operations (Create, Read, Update, Delete) it performs on each entity. This matrix helps:

- Identify data dependencies between use cases
- Plan transaction boundaries
- Design API endpoints
- Understand entity lifecycle
- Audit data access patterns

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

## Job Requisition Management (UC-001 to UC-012)

| Entity | UC-001 | UC-002 | UC-003 | UC-004 | UC-005 | UC-006 | UC-007 | UC-008 | UC-009 | UC-010 | UC-011 | UC-012 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | Create Job | Edit Job | Submit Approval | Approve Req | Reject Req | Open Job | Hold Job | Close Job | Clone Job | Config Stages | Post Boards | Remove Boards |
| **organizations** | R | R | R | R | R | R | R | R | R | R | R | R |
| **users** | R | R | R | R | R | R | R | R | R | R | R | R |
| **departments** | R | R | - | - | - | - | - | - | R | - | - | - |
| **jobs** | C | U | U | U | U | U | U | U | C | R | U | U |
| **job_stages** | C | - | - | - | - | - | - | - | C | CUD | - | - |
| **job_approvals** | (C) | - | C | U | U | - | - | - | - | - | - | - |
| **job_board_postings** | - | - | - | - | - | - | - | - | - | - | C | D |
| **stages** | R | - | - | - | - | - | - | - | R | R | - | - |
| **audit_logs** | C | C | C | C | C | C | C | C | C | C | C | C |

### Transaction Summary

| Use Case | Primary Table | Secondary Tables | Audit |
|----------|---------------|------------------|-------|
| UC-001 Create Job | jobs | job_stages, job_approvals | Yes |
| UC-002 Edit Job | jobs | - | Yes |
| UC-003 Submit Approval | job_approvals, jobs | - | Yes |
| UC-004 Approve Requisition | job_approvals, jobs | - | Yes |
| UC-005 Reject Requisition | job_approvals, jobs | - | Yes |
| UC-006 Open Job | jobs | - | Yes |
| UC-007 Put Job On Hold | jobs | - | Yes |
| UC-008 Close Job | jobs | - | Yes |
| UC-009 Clone Job | jobs | job_stages | Yes |
| UC-010 Configure Stages | job_stages | - | Yes |
| UC-011 Post to Boards | job_board_postings, jobs | - | Yes |
| UC-012 Remove from Boards | job_board_postings, jobs | - | Yes |

---

## Candidate Management (UC-050 to UC-063)

| Entity | UC-050 | UC-051 | UC-052 | UC-053 | UC-054 | UC-055 | UC-056 | UC-057 | UC-058 | UC-059 | UC-060 | UC-061 | UC-062 | UC-063 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | Add Manual | Import | Referral | Agency Sub | Edit Profile | Upload Resume | Parse Resume | Add Note | Tag | Detect Dupe | Merge | Search | Create Pool | Add to Pool |
| **organizations** | R | R | R | R | R | R | R | R | R | R | R | R | R | R |
| **users** | R | R | R | R | R | R | - | R | R | - | R | R | R | R |
| **candidates** | C | C | C | C | U | (U) | U | R | U | R | U | R | R | R |
| **resumes** | (C) | (C) | (C) | (C) | - | C | U | - | - | - | (U) | R | - | - |
| **candidate_notes** | - | - | - | - | - | - | - | C | - | - | (C) | - | - | - |
| **candidate_tags** | - | - | - | - | - | - | - | - | CUD | - | (U) | R | - | - |
| **tags** | - | - | - | - | - | - | - | - | R | - | - | R | - | - |
| **talent_pools** | - | - | - | - | - | - | - | - | - | - | - | R | C | R |
| **talent_pool_members** | - | - | - | - | - | - | - | - | - | - | - | - | - | C |
| **agencies** | - | - | - | R | - | - | - | - | - | - | - | - | - | - |
| **audit_logs** | C | C | C | C | C | C | C | C | C | - | C | - | C | C |

### Transaction Summary

| Use Case | Primary Table | Secondary Tables | Audit |
|----------|---------------|------------------|-------|
| UC-050 Add Candidate | candidates | resumes | Yes |
| UC-051 Import Candidates | candidates | resumes | Yes |
| UC-052 Submit Referral | candidates | resumes, applications | Yes |
| UC-053 Agency Submission | candidates | resumes, applications | Yes |
| UC-054 Edit Profile | candidates | - | Yes |
| UC-055 Upload Resume | resumes | candidates | Yes |
| UC-056 Parse Resume | resumes, candidates | - | Yes |
| UC-057 Add Note | candidate_notes | - | Yes |
| UC-058 Tag Candidate | candidate_tags | - | Yes |
| UC-059 Detect Duplicates | candidates | - | No |
| UC-060 Merge Candidates | candidates | resumes, applications, notes | Yes |
| UC-061 Search Candidates | candidates, resumes | - | No |
| UC-062 Create Talent Pool | talent_pools | - | Yes |
| UC-063 Add to Talent Pool | talent_pool_members | - | Yes |

---

## Application & Pipeline (UC-100 to UC-110)

| Entity | UC-100 | UC-101 | UC-102 | UC-103 | UC-104 | UC-105 | UC-106 | UC-107 | UC-108 | UC-109 | UC-110 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | Apply | Add to Job | View Pipeline | Move Stage | Bulk Move | Reject | Bulk Reject | Withdraw | Reopen | View History | Transfer |
| **organizations** | R | R | R | R | R | R | R | R | R | R | R |
| **users** | - | R | R | R | R | R | R | - | R | R | R |
| **jobs** | R | R | R | R | R | R | R | R | R | R | R |
| **candidates** | CU | R | R | R | R | R | R | R | R | R | R |
| **applications** | C | C | R | U | U | U | U | U | U | R | U |
| **stage_transitions** | C | C | R | C | C | C | C | C | C | R | C |
| **stages** | R | R | R | R | R | R | R | R | R | R | R |
| **rejection_reasons** | - | - | - | - | - | R | R | - | - | R | - |
| **resumes** | C | - | R | - | - | - | - | - | - | R | - |
| **consents** | C | - | - | - | - | - | - | - | - | - | - |
| **custom_field_responses** | (C) | - | R | - | - | - | - | - | - | R | - |
| **audit_logs** | C | C | - | C | C | C | C | C | C | R | C |

### Transaction Summary

| Use Case | Primary Table | Secondary Tables | Audit |
|----------|---------------|------------------|-------|
| UC-100 Apply for Job | applications | candidates, resumes, stage_transitions, consents | Yes |
| UC-101 Add to Job | applications | stage_transitions | Yes |
| UC-102 View Pipeline | applications | candidates, stages | No |
| UC-103 Move Stage | applications | stage_transitions | Yes |
| UC-104 Bulk Move | applications | stage_transitions | Yes |
| UC-105 Reject | applications | stage_transitions | Yes |
| UC-106 Bulk Reject | applications | stage_transitions | Yes |
| UC-107 Withdraw | applications | stage_transitions | Yes |
| UC-108 Reopen | applications | stage_transitions | Yes |
| UC-109 View History | stage_transitions | audit_logs | No |
| UC-110 Transfer | applications | stage_transitions | Yes |

---

## Interview Management (UC-150 to UC-160)

| Entity | UC-150 | UC-151 | UC-152 | UC-153 | UC-154 | UC-155 | UC-156 | UC-157 | UC-158 | UC-159 | UC-160 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | Schedule | Panel | Send Invite | Self-Sched | Reschedule | Cancel | Confirm | No-Show | Complete | View Kit | Manage Templates |
| **organizations** | R | R | R | R | R | R | R | R | R | R | R |
| **users** | R | R | R | - | R | R | R | R | R | R | R |
| **applications** | R | R | R | R | R | R | R | R | U | R | - |
| **candidates** | R | R | R | R | R | R | R | R | R | R | - |
| **interviews** | C | C | R | C | U | U | U | U | U | R | - |
| **interview_participants** | C | C | R | C | U | U | U | - | R | R | - |
| **interview_templates** | R | R | - | - | - | - | - | - | - | R | CUD |
| **interview_questions** | - | - | - | - | - | - | - | - | - | R | CUD |
| **calendar_events** | - | - | C | C | U | D | - | - | - | - | - |
| **availability_slots** | - | - | - | R | - | - | - | - | - | - | - |
| **audit_logs** | C | C | C | C | C | C | C | C | C | - | C |

### Transaction Summary

| Use Case | Primary Table | Secondary Tables | Audit |
|----------|---------------|------------------|-------|
| UC-150 Schedule Interview | interviews | interview_participants | Yes |
| UC-151 Create Panel | interviews | interview_participants | Yes |
| UC-152 Send Invite | calendar_events | interviews | Yes |
| UC-153 Self-Schedule | interviews | interview_participants, calendar_events | Yes |
| UC-154 Reschedule | interviews | calendar_events | Yes |
| UC-155 Cancel | interviews | calendar_events | Yes |
| UC-156 Confirm | interview_participants | - | Yes |
| UC-157 No-Show | interviews | - | Yes |
| UC-158 Complete | interviews, applications | - | Yes |
| UC-159 View Kit | interview_templates | interview_questions | No |
| UC-160 Manage Templates | interview_templates | interview_questions | Yes |

---

## Evaluation & Feedback (UC-200 to UC-208)

| Entity | UC-200 | UC-201 | UC-202 | UC-203 | UC-204 | UC-205 | UC-206 | UC-207 | UC-208 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | Submit Scorecard | Rate Competencies | Add Notes | View Feedback | Request Feedback | Hiring Decision | Approve Progress | Manage Competencies | Create Template |
| **organizations** | R | R | R | R | R | R | R | R | R |
| **users** | R | R | R | R | R | R | R | R | R |
| **interviews** | R | R | R | R | R | R | R | - | R |
| **applications** | R | R | R | R | R | U | U | - | - |
| **scorecards** | C | U | U | R | R | R | R | - | - |
| **scorecard_attributes** | C | CU | - | R | - | R | R | - | - |
| **competencies** | R | R | - | R | - | R | - | CUD | R |
| **scorecard_templates** | R | R | - | - | - | - | - | - | CUD |
| **stage_approvals** | - | - | - | - | - | - | CU | - | - |
| **email_logs** | - | - | - | - | C | - | - | - | - |
| **audit_logs** | C | C | C | - | C | C | C | C | C |

### Transaction Summary

| Use Case | Primary Table | Secondary Tables | Audit |
|----------|---------------|------------------|-------|
| UC-200 Submit Scorecard | scorecards | scorecard_attributes | Yes |
| UC-201 Rate Competencies | scorecard_attributes | scorecards | Yes |
| UC-202 Add Notes | scorecards | - | Yes |
| UC-203 View Feedback | scorecards | scorecard_attributes | No |
| UC-204 Request Feedback | email_logs | - | Yes |
| UC-205 Hiring Decision | applications | - | Yes |
| UC-206 Approve Progress | stage_approvals, applications | - | Yes |
| UC-207 Manage Competencies | competencies | - | Yes |
| UC-208 Create Template | scorecard_templates | competencies | Yes |

---

## Offer Management (UC-250 to UC-261)

| Entity | UC-250 | UC-251 | UC-252 | UC-253 | UC-254 | UC-255 | UC-256 | UC-257 | UC-258 | UC-259 | UC-260 | UC-261 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | Create | Submit | Approve | Reject | Send | Accept | Decline | Negotiate | Withdraw | Mark Hired | Manage Templates | E-Sign |
| **organizations** | R | R | R | R | R | R | R | R | R | R | R | R |
| **users** | R | R | R | R | R | - | - | R | R | R | R | - |
| **applications** | R | R | R | R | R | U | U | R | U | U | - | R |
| **candidates** | R | R | - | - | R | R | R | R | R | R | - | R |
| **jobs** | R | R | - | - | R | - | - | R | - | R | - | - |
| **offers** | C | U | U | U | U | U | U | U | U | R | - | U |
| **offer_approvals** | - | C | U | U | - | - | - | - | - | - | - | - |
| **offer_templates** | R | - | - | - | R | - | - | R | - | - | CUD | - |
| **documents** | - | - | - | - | C | - | - | - | - | - | - | CU |
| **email_logs** | - | - | - | - | C | - | - | - | C | - | - | - |
| **stage_transitions** | - | - | - | - | - | C | C | - | C | C | - | - |
| **audit_logs** | C | C | C | C | C | C | C | C | C | C | C | C |

### Transaction Summary

| Use Case | Primary Table | Secondary Tables | Audit |
|----------|---------------|------------------|-------|
| UC-250 Create Offer | offers | - | Yes |
| UC-251 Submit for Approval | offers | offer_approvals | Yes |
| UC-252 Approve Offer | offer_approvals, offers | - | Yes |
| UC-253 Reject Offer | offer_approvals, offers | - | Yes |
| UC-254 Send to Candidate | offers | documents, email_logs | Yes |
| UC-255 Accept Offer | offers, applications | stage_transitions | Yes |
| UC-256 Decline Offer | offers, applications | stage_transitions | Yes |
| UC-257 Negotiate | offers | - | Yes |
| UC-258 Withdraw Offer | offers, applications | email_logs, stage_transitions | Yes |
| UC-259 Mark Hired | applications | stage_transitions | Yes |
| UC-260 Manage Templates | offer_templates | - | Yes |
| UC-261 E-Sign | offers | documents | Yes |

---

## Compliance & Audit (UC-300 to UC-311)

| Entity | UC-300 | UC-301 | UC-302 | UC-303 | UC-304 | UC-305 | UC-306 | UC-307 | UC-308 | UC-309 | UC-310 | UC-311 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | EEOC | Consent | Init BGC | Receive BGC | Init Adverse | Complete Adverse | EEOC Report | View Audit | Export Audit | Delete Request | Retention | Doc Decision |
| **organizations** | R | R | R | R | R | R | R | R | R | R | RU | R |
| **users** | - | - | R | - | R | R | R | R | R | R | R | R |
| **candidates** | R | R | R | R | R | R | R | R | R | (D) | R | R |
| **applications** | R | R | R | U | R | U | R | R | R | (D) | R | R |
| **eeoc_responses** | C | - | - | - | - | - | R | - | - | (D) | - | - |
| **consents** | - | C | R | - | - | - | - | R | R | R | - | - |
| **background_checks** | - | - | C | U | R | R | - | R | R | - | - | - |
| **adverse_actions** | - | - | - | - | C | U | - | R | R | - | - | - |
| **audit_logs** | C | C | C | C | C | C | R | R | R | C | C | C |
| **hiring_decisions** | - | - | - | - | - | - | R | R | R | - | - | C |
| **data_retention_policies** | - | - | - | - | - | - | - | - | - | R | CUD | - |

### Transaction Summary

| Use Case | Primary Table | Secondary Tables | Audit |
|----------|---------------|------------------|-------|
| UC-300 Collect EEOC | eeoc_responses | - | Yes |
| UC-301 Record Consent | consents | - | Yes |
| UC-302 Initiate BGC | background_checks | - | Yes |
| UC-303 Receive Results | background_checks, applications | - | Yes |
| UC-304 Initiate Adverse | adverse_actions | - | Yes |
| UC-305 Complete Adverse | adverse_actions, applications | - | Yes |
| UC-306 EEOC Report | eeoc_responses | applications, candidates | No |
| UC-307 View Audit | audit_logs | - | No |
| UC-308 Export Audit | audit_logs | - | Yes |
| UC-309 Delete Request | candidates | applications, resumes, etc. | Yes |
| UC-310 Retention Policy | data_retention_policies, organizations | - | Yes |
| UC-311 Document Decision | hiring_decisions | - | Yes |

---

## Reporting & Analytics (UC-350 to UC-359)

| Entity | UC-350 | UC-351 | UC-352 | UC-353 | UC-354 | UC-355 | UC-356 | UC-357 | UC-358 | UC-359 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | Dashboard | Time-to-Hire | Source Effect | Pipeline Conv | Diversity | Recruiter Activity | Open Reqs | Offer Accept | Schedule | Export |
| **organizations** | R | R | R | R | R | R | R | R | R | R |
| **users** | R | R | R | R | R | R | R | R | R | R |
| **jobs** | R | R | R | R | R | R | R | R | R | R |
| **applications** | R | R | R | R | R | R | R | R | R | R |
| **candidates** | R | R | R | R | R | R | R | R | R | R |
| **stage_transitions** | R | R | R | R | R | R | R | - | R | R |
| **offers** | R | R | - | - | - | R | - | R | R | R |
| **eeoc_responses** | - | - | - | - | R | - | - | - | - | - |
| **audit_logs** | R | - | - | - | - | R | - | - | - | - |
| **scheduled_reports** | - | - | - | - | - | - | - | - | CUD | - |

### Note
All reporting use cases are read-only against operational tables. They may create scheduled_reports records but do not modify source data.

---

## Career Site & Candidate Portal (UC-400 to UC-410)

| Entity | UC-400 | UC-401 | UC-402 | UC-403 | UC-404 | UC-405 | UC-406 | UC-407 | UC-408 | UC-409 | UC-410 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | Browse | Search | View Detail | Apply | Create Acct | Check Status | Update Profile | Upload Docs | Config Site | Branding | App Questions |
| **organizations** | R | R | R | R | R | R | R | R | RU | RU | R |
| **jobs** | R | R | R | R | - | R | - | - | - | - | R |
| **candidates** | - | - | - | CU | C | R | U | R | - | - | - |
| **applications** | - | - | - | C | - | R | - | R | - | - | - |
| **resumes** | - | - | - | C | - | - | - | C | - | - | - |
| **consents** | - | - | - | C | C | - | - | - | - | - | - |
| **candidate_accounts** | - | - | - | - | C | R | U | - | - | - | - |
| **documents** | - | - | - | - | - | R | - | C | - | - | - |
| **career_site_settings** | R | R | R | R | R | R | R | R | CU | CU | - |
| **custom_fields** | - | - | - | R | - | - | - | - | - | - | CUD |
| **audit_logs** | - | - | - | C | C | - | C | C | C | C | C |

---

## Integrations (UC-450 to UC-460)

| Entity | UC-450 | UC-451 | UC-452 | UC-453 | UC-454 | UC-455 | UC-456 | UC-457 | UC-458 | UC-459 | UC-460 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | Config Boards | Sync Jobs | Import Apps | Config HRIS | Export Hire | Config Calendar | Sync Calendar | Config SSO | API Keys | Webhooks | View Logs |
| **organizations** | RU | R | R | RU | R | RU | R | RU | R | R | R |
| **jobs** | - | R | R | - | R | - | - | - | - | - | - |
| **candidates** | - | - | CU | - | R | - | - | - | - | - | - |
| **applications** | - | - | C | - | R | - | - | - | - | - | - |
| **integration_configs** | CUD | R | R | CUD | R | CUD | R | CUD | R | R | R |
| **job_board_postings** | - | CU | - | - | - | - | - | - | - | - | - |
| **hris_exports** | - | - | - | - | C | - | - | - | - | - | - |
| **calendar_connections** | - | - | - | - | - | CUD | R | - | - | - | - |
| **sso_configs** | - | - | - | - | - | - | - | CUD | - | - | - |
| **api_keys** | - | - | - | - | - | - | - | - | CUD | - | R |
| **webhooks** | - | - | - | - | - | - | - | - | - | CUD | R |
| **integration_logs** | - | C | C | - | C | - | C | - | - | C | R |
| **audit_logs** | C | C | C | C | C | C | C | C | C | C | - |

---

## Administration (UC-500 to UC-509)

| Entity | UC-500 | UC-501 | UC-502 | UC-503 | UC-504 | UC-505 | UC-506 | UC-507 | UC-508 | UC-509 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | Create User | Edit User | Deactivate | Assign Role | Manage Depts | Org Settings | Rejection Reasons | Email Templates | System Health | Custom Fields |
| **organizations** | R | R | R | R | R | RU | R | R | R | R |
| **users** | C | U | U | U | R | R | R | R | R | R |
| **user_roles** | C | - | - | CUD | - | - | - | - | - | - |
| **departments** | - | - | - | - | CUD | - | - | - | - | - |
| **rejection_reasons** | - | - | - | - | - | - | CUD | - | - | - |
| **email_templates** | - | - | - | - | - | - | - | CUD | - | - |
| **custom_fields** | - | - | - | - | - | - | - | - | - | CUD |
| **system_health** | - | - | - | - | - | - | - | - | R | - |
| **audit_logs** | C | C | C | C | C | C | C | C | - | C |

---

## Communication (UC-550 to UC-558)

| Entity | UC-550 | UC-551 | UC-552 | UC-553 | UC-554 | UC-555 | UC-556 | UC-557 | UC-558 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| | Send Email | Bulk Email | Schedule | Sequence | Send SMS | In-App Notif | Notif Prefs | View History | Track Engage |
| **organizations** | R | R | R | R | R | R | R | R | R |
| **users** | R | R | R | R | R | R | - | R | R |
| **candidates** | R | R | R | R | R | R | U | R | R |
| **applications** | R | R | R | R | R | R | - | R | R |
| **email_logs** | C | C | C | C | - | - | - | R | RU |
| **sms_logs** | - | - | - | - | C | - | - | R | RU |
| **notifications** | - | - | - | - | - | C | R | - | - |
| **email_templates** | R | R | R | R | - | - | - | R | - |
| **email_sequences** | - | - | - | CUD | - | - | - | R | - |
| **scheduled_emails** | - | - | C | C | - | - | - | R | - |
| **notification_preferences** | - | - | - | - | - | R | CU | - | - |
| **audit_logs** | C | C | C | C | C | - | C | - | - |

---

## Entity Access Summary

This table shows which use cases access each major entity.

| Entity | Create | Read | Update | Delete | Total UCs |
|--------|--------|------|--------|--------|-----------|
| **applications** | 4 | 45+ | 20 | 1 | 50+ |
| **candidates** | 6 | 40+ | 10 | 1 | 45+ |
| **jobs** | 2 | 35+ | 12 | 0 | 40+ |
| **users** | 1 | 50+ | 4 | 0 | 50+ |
| **audit_logs** | 70+ | 5 | 0 | 0 | 75+ |
| **stage_transitions** | 12 | 15 | 0 | 0 | 20+ |
| **resumes** | 5 | 10 | 2 | 0 | 12 |
| **interviews** | 4 | 12 | 8 | 0 | 15 |
| **offers** | 1 | 10 | 9 | 0 | 12 |
| **scorecards** | 1 | 5 | 3 | 0 | 6 |
| **email_logs** | 8 | 8 | 2 | 0 | 12 |
| **consents** | 4 | 5 | 0 | 0 | 6 |

---

## High-Transaction Entities

Entities with highest write frequency (focus for optimization):

1. **audit_logs** - Every user action creates an entry
2. **applications** - Core workflow entity
3. **stage_transitions** - Every pipeline move
4. **email_logs** - All communications
5. **candidates** - New applicants continuously

## Read-Heavy Entities

Entities with highest read:write ratio:

1. **organizations** - Read on every request (tenant check)
2. **users** - Read for auth/permissions
3. **stages** - Read for pipeline display
4. **jobs** - Read for listings, pipeline views
5. **email_templates** - Read when sending, rarely modified
