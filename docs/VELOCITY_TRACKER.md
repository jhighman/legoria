# Velocity Tracker - AI-Driven Development

## Overview

This document tracks velocity for AI-driven development sessions. Since we operate in hours rather than weeks, we measure differently than traditional Agile.

---

## Phase 1: Foundation MVP - COMPLETE

### Sprint 0: Project Setup
| Metric | Value |
|--------|-------|
| **Planned Points** | 24 |
| **Delivered Points** | 24 |
| **Tasks Completed** | 6 |
| **Lines Added** | ~400 |
| **Files Created/Modified** | 38 |
| **Tests** | 0 |

**Deliverables:** Migrations, FactoryBot, Seeds, Bootstrap 5.3, Active Storage S3

### Sprint 1: Core Models & Multi-Tenancy
| Metric | Value |
|--------|-------|
| **Planned Points** | 40 |
| **Delivered Points** | 40 |
| **Models Created** | 11 |
| **Concerns Created** | 2 |
| **Policies Created** | 6 |
| **Tests Written** | 80 |

**Deliverables:** Current context, OrganizationScoped, Discardable, Organization, User (Devise), Role, Permission, RolePermission, UserRole, Department, Stage, RejectionReason, Pundit policies

### Sprint 2: Job Requisitions
| Metric | Value |
|--------|-------|
| **Planned Points** | 52 |
| **Delivered Points** | 52 |
| **Models Created** | 4 |
| **Controllers Created** | 2 |
| **Tests (Cumulative)** | 158 |

**Deliverables:** Job model with state machine, JobStage, JobApproval, JobTemplate, JobsController, Job views

### Sprint 3: RBAC Admin & Reference Data
| Metric | Value |
|--------|-------|
| **Planned Points** | 67 |
| **Delivered Points** | 67 |
| **Models Created** | 2 |
| **Controllers Created** | 4 |
| **Tests (Cumulative)** | 250 |

**Deliverables:** Admin namespace, User/Role management UI, LookupType/LookupValue for reference data, i18n translations

### Sprint 4: Pipeline & Workflow
| Metric | Value |
|--------|-------|
| **Planned Points** | 47 |
| **Delivered Points** | 47 |
| **Services Created** | 2 |
| **Tests (Cumulative)** | 320 |

**Deliverables:** Kanban pipeline with Stimulus drag-drop, stage transitions, rejection workflow, candidate ratings/starring

### Sprint 5: Audit Trail & Dashboard
| Metric | Value |
|--------|-------|
| **Planned Points** | 45 |
| **Delivered Points** | 45 |
| **Models Created** | 1 |
| **Concerns Created** | 1 |
| **Tests (Cumulative)** | 395 |

**Deliverables:** Immutable AuditLog, Auditable concern, SLA alerts, recruiter dashboard

### Sprint 6: Career Site & Polish
| Metric | Value |
|--------|-------|
| **Planned Points** | 50 |
| **Delivered Points** | 50 |
| **Controllers Created** | 2 |
| **Mailers Created** | 1 |
| **Tests (Cumulative)** | 431 |

**Deliverables:** Public career site, job listings, frictionless apply, tokenized status tracking, email notifications

**Phase 1 Total: 325 points, 431 tests**

---

## Phase 2: Scheduling & Evaluation - COMPLETE

### Sprint 7: Interview Scheduling
| Metric | Value |
|--------|-------|
| **Planned Points** | 55 |
| **Delivered Points** | 55 |
| **Models Created** | 4 (Interview, InterviewParticipant, CalendarIntegration, AvailabilitySlot) |
| **Tests (Cumulative)** | 510 |

**Deliverables:** Interview model with state machine, participants, calendar integrations, scheduling UI

### Sprint 8: Scorecards & Feedback
| Metric | Value |
|--------|-------|
| **Planned Points** | 45 |
| **Delivered Points** | 45 |
| **Models Created** | 4 (ScorecardTemplate, ScorecardSection, ScorecardItem, ScorecardResponse) |
| **Tests (Cumulative)** | 570 |

**Deliverables:** Scorecard templates with sections and items, competency ratings, visibility rules

### Sprint 9: Interview Kits & Decisions
| Metric | Value |
|--------|-------|
| **Planned Points** | 35 |
| **Delivered Points** | 35 |
| **Models Created** | 4 (QuestionBank, InterviewKit, HiringDecision, HiringDecisionApproval) |
| **Tests (Cumulative)** | 636 |

**Deliverables:** Question banks, interview kits, immutable hiring decisions, decision approvals

**Phase 2 Total: 135 points, 205 new tests (636 cumulative)**

---

## Phase 3: Enhanced Candidate Experience - COMPLETE

### Sprint 10: Candidate Experience
| Metric | Value |
|--------|-------|
| **Planned Points** | 50 |
| **Delivered Points** | 50 |
| **Models Created** | 5 (OrganizationBranding, ApplicationQuestion, CandidateAccount, CandidateDocument, InterviewSelfSchedule) |
| **Tests (Cumulative)** | 699 |

**Deliverables:** Organization branding, custom application questions, candidate accounts, document management, interview self-scheduling

**Phase 3 Total: 50 points, 63 new tests (699 cumulative)**

---

## Phase 4: Offers & Compliance - COMPLETE

### Sprint 11: Offer Management
| Metric | Value |
|--------|-------|
| **Planned Points** | 35 |
| **Delivered Points** | 35 |
| **Models Created** | 3 (OfferTemplate, Offer, OfferApproval) |
| **Tests (Cumulative)** | 760 |

**Deliverables:** Offer templates with variable substitution, offer workflow, multi-step approval chain

### Sprint 12: Compliance
| Metric | Value |
|--------|-------|
| **Planned Points** | 35 |
| **Delivered Points** | 35 |
| **Models Created** | 5 (EeocResponse, GdprConsent, DataRetentionPolicy, DeletionRequest, AdverseAction) |
| **Tests (Cumulative)** | 819 |

**Deliverables:** EEOC voluntary self-identification, GDPR consent, data retention, right-to-deletion, FCRA adverse action

**Phase 4 Total: 70 points, 120 new tests (819 cumulative)**

---

## Phase 5: Intelligence & Automation - COMPLETE

### Sprint 13: Intelligence
| Metric | Value |
|--------|-------|
| **Planned Points** | 80 |
| **Delivered Points** | 80 |
| **Models Created** | 10 (ParsedResume, CandidateSkill, SavedSearch, SearchAlert, TalentPool, TalentPoolMember, AutomationRule, AutomationLog, JobRequirement, CandidateScore) |
| **Services Created** | 2 (ResumeParsingService, CandidateScoringService) |
| **Tests (Cumulative)** | 944 |

**Deliverables:** Resume parsing, skills extraction, saved searches, talent pools, automation rules, candidate scoring

**Phase 5 Total: 80 points, 125 new tests (944 cumulative)**

---

## Phase 6: Integrations & API - COMPLETE

### Sprint 14: Integrations
| Metric | Value |
|--------|-------|
| **Planned Points** | 100 |
| **Delivered Points** | 100 |
| **Models Created** | 11 (Integration, JobBoardPosting, HrisExport, BackgroundCheck, ApiKey, Webhook, WebhookDelivery, SsoConfiguration, SsoIdentity, IntegrationLog, UserSession) |
| **Tests (Cumulative)** | 1162 |

**Deliverables:** External integrations framework, webhooks with retries, API keys with rate limiting, SAML/OIDC SSO

**Phase 6 Total: 100 points, 218 new tests (1162 cumulative)**

---

## Phase 7: Analytics & Reporting - COMPLETE

### Sprint 15: Core Metrics & Dashboards
| Metric | Value |
|--------|-------|
| **Planned Points** | 55 |
| **Delivered Points** | 55 |
| **Query Objects Created** | 6 (TimeToHire, SourceEffectiveness, Pipeline, OfferAcceptance, RecruiterProductivity, RequisitionAging) |
| **Controllers Created** | 4 |
| **Tests (Cumulative)** | 1200 |

**Deliverables:** ApplicationQuery base class, DateRangeFilter, core metric queries, Chart.js, CSV export

### Sprint 16: Diversity & Compliance Reporting
| Metric | Value |
|--------|-------|
| **Planned Points** | 55 |
| **Delivered Points** | 55 |
| **Query Objects Created** | 4 (EeocReport, DiversityMetrics, AdverseImpact, ApplicationQuery base) |
| **Models Created** | 1 (ReportSnapshot) |
| **Controllers Created** | 3 |
| **Tests (Cumulative)** | 1236 |

**Deliverables:** EEOC reporting with anonymization, diversity metrics, 4/5ths rule analysis, PDF export

**Phase 7 Total: 110 points, 74 new tests (1236 cumulative)**

---

## Phase 8: I-9 & Work Authorization - COMPLETE

### Sprint 17: I-9 Core Models
| Metric | Value |
|--------|-------|
| **Planned Points** | 60 |
| **Delivered Points** | 60 |
| **Models Created** | 4 (I9Verification, WorkAuthorization, I9Document, EVerifyCase) |
| **Services Created** | 3 (InitiateI9VerificationService, CompleteI9Section1Service, CompleteI9Section2Service) |
| **Jobs Created** | 3 (I9NotificationJob, I9DeadlineReminderJob, WorkAuthorizationExpirationJob) |
| **Mailers Created** | 2 (I9Mailer, WorkAuthorizationMailer) |
| **Tests (Cumulative)** | 1349 |

**Deliverables:** I9Verification state machine, business day deadline calculations, List A/B/C document validation, work authorization expiration tracking, E-Verify case management, encrypted sensitive fields, candidate portal Section 1 workflow

### Sprint 18: Section 2/3 & Dashboard
| Metric | Value |
|--------|-------|
| **Planned Points** | 60 |
| **Delivered Points** | 60 |
| **Controllers Created** | 5 (CandidatePortal::I9VerificationsController, Admin::I9VerificationsController, Admin::WorkAuthorizationsController, Reports::I9ComplianceController, Reports::WorkAuthorizationsController) |
| **Query Objects Created** | 1 (I9ComplianceQuery) |
| **Policies Created** | 2 (I9VerificationPolicy, WorkAuthorizationPolicy) |
| **Views Created** | 12 |
| **Tests (Cumulative)** | 1415 |

**Deliverables:** Admin I-9 verification workflow (Section 2/3 completion), work authorization management, I-9 compliance reporting with metrics, work authorization expiration tracking dashboard, candidate portal Section 1 completion, comprehensive Pundit policies

**Phase 8 Total: 120 points, 179 new tests (1415 cumulative)**

---

## Cumulative Summary

| Phase | Theme | Points | New Tests | Total Tests |
|-------|-------|--------|-----------|-------------|
| 1 | Foundation MVP | 325 | 431 | 431 |
| 2 | Scheduling & Evaluation | 135 | 205 | 636 |
| 3 | Enhanced Candidate Experience | 50 | 63 | 699 |
| 4 | Offers & Compliance | 70 | 120 | 819 |
| 5 | Intelligence & Automation | 80 | 125 | 944 |
| 6 | Integrations & API | 100 | 218 | 1162 |
| 7 | Analytics & Reporting | 110 | 74 | 1236 |
| 8 | I-9 & Work Authorization | 120 | 179 | 1415 |
| **Total** | | **990** | **1415** | **1415** |

---

## Velocity Analysis

### Points per Phase
| Phase | Points | Sprints | Avg Points/Sprint |
|-------|--------|---------|-------------------|
| Phase 1 | 325 | 7 | 46.4 |
| Phase 2 | 135 | 3 | 45.0 |
| Phase 3 | 50 | 1 | 50.0 |
| Phase 4 | 70 | 2 | 35.0 |
| Phase 5 | 80 | 1 | 80.0 |
| Phase 6 | 100 | 1 | 100.0 |
| Phase 7 | 110 | 2 | 55.0 |
| Phase 8 | 120 | 2 | 60.0 |

### Test Coverage Growth
- Phase 1: 431 tests (foundation)
- Phase 2: +205 tests (+47.6%)
- Phase 3: +63 tests (+9.9%)
- Phase 4: +120 tests (+17.2%)
- Phase 5: +125 tests (+15.3%)
- Phase 6: +218 tests (+23.1%)
- Phase 7: +74 tests (+6.4%)
- Phase 8: +179 tests (+14.5%)

### Velocity Factors
AI-driven velocity varies based on:
- **Complexity**: CRUD models ~20 pts/hr, complex workflows ~10 pts/hr
- **Test Coverage**: Writing tests adds ~40% to base time
- **Integration Work**: External APIs require more research
- **Query Objects**: Read-only patterns are faster than CRUD

---

## Architecture Metrics

### Models Created: 60+
```
Phase 1: Organization, User, Role, Permission, Department, Stage, Job, Candidate, Application, StageTransition, AuditLog, etc.
Phase 2: Interview, InterviewParticipant, CalendarIntegration, ScorecardTemplate, HiringDecision, etc.
Phase 3: OrganizationBranding, ApplicationQuestion, CandidateAccount, CandidateDocument, InterviewSelfSchedule
Phase 4: OfferTemplate, Offer, OfferApproval, EeocResponse, GdprConsent, DeletionRequest, AdverseAction
Phase 5: ParsedResume, CandidateSkill, SavedSearch, TalentPool, AutomationRule, CandidateScore, etc.
Phase 6: Integration, ApiKey, Webhook, SsoConfiguration, BackgroundCheck, etc.
Phase 7: ReportSnapshot
```

### Query Objects Created: 10
```
app/queries/
├── application_query.rb           # Base class
├── time_to_hire_query.rb
├── source_effectiveness_query.rb
├── pipeline_conversion_query.rb
├── offer_acceptance_query.rb
├── recruiter_productivity_query.rb
├── requisition_aging_query.rb
├── eeoc_report_query.rb
├── diversity_metrics_query.rb
└── adverse_impact_query.rb
```

### Services Created: 15+
```
app/services/
├── application_service.rb         # Base class
├── move_stage_service.rb
├── rejection_service.rb
├── resume_parsing_service.rb
├── candidate_scoring_service.rb
└── ... more
```

### Controllers: 30+
```
- Core: Dashboard, Jobs, Candidates, Applications, Pipeline
- Admin: Users, Roles, Lookups
- Public: CareerSite, PublicApplications
- Portal: CandidatePortal
- Reports: Dashboard, TimeToHire, Sources, Pipeline, Operational, EEOC, Diversity
- API: Various resource controllers
```

---

## Session Planning

### Optimal Session Structure
Based on velocity data, optimal AI development sessions are:
- **Duration:** 2-4 hours (mental model stays fresh)
- **Scope:** 30-80 points (1-2 sprints)
- **Pattern:** Planning → Implementation → Testing → Review

### Pre-Session Checklist
- [ ] Review velocity metrics from previous session
- [ ] Read sprint backlog for upcoming work
- [ ] Identify key decisions/blockers
- [ ] Set session goals (points to complete)

### Post-Session Checklist
- [ ] Update velocity tracker with actuals
- [ ] Commit and push all changes
- [ ] Run full test suite
- [ ] Update documentation

---

## Key Learnings

1. **Fixtures vs Factories**: Use fixtures for integration tests, factories for unit tests
2. **Query Objects**: Excellent pattern for complex read operations
3. **Service Objects**: Dry::Monads provides clean result handling
4. **State Machines**: state_machines-activerecord works well with Rails 8
5. **Multi-tenancy**: Current.organization pattern is effective and simple
6. **Testing**: 1236 tests provide confidence for refactoring
7. **Documentation**: Keep CLAUDE.md updated for AI context

---

*Last Updated: Phase 7 Complete - 1236 tests passing*
