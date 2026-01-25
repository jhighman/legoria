# Ledgoria

**A compliance-first Applicant Tracking System with built-in identity verification and trust infrastructure.**

---

## Vision

Hiring is broken. Not because companies lack tools—but because the tools they have optimize for speed at the expense of defensibility, candidate experience, and trust.

**Ledgoria** is an ATS built on a different premise: *every hiring decision should be both fast and defensible*.

### The Problem

Traditional ATS platforms treat compliance as an afterthought—a checkbox at the end of a workflow designed for throughput. This creates real costs:

- **For employers:** Audit failures, adverse action missteps, inconsistent documentation, and legal exposure
- **For candidates:** Black-hole applications, opaque processes, redundant screening, and friction at every step
- **For recruiters:** Cognitive overload, manual compliance tracking, and tools that fight against good judgment

Meanwhile, the trust layer of hiring—identity verification, credential validation, background screening—remains bolted on rather than built in.

### Our Approach

Ledgoria inverts the model. Compliance isn't a feature; it's the architecture.

**1. Defensible by Default**
- Structured rejection reasons with audit trails
- Adverse action workflows built into the pipeline
- Decision documentation at every stage transition
- Immutable records for regulatory inspection

**2. Candidate-Centric Experience**
- Frictionless apply (no account required)
- Transparent status visibility
- Self-scheduling that respects candidate time
- Mobile-first, accessible design

**3. Trust Infrastructure**
- Native integration with Ledgoria's identity verification
- Portable candidate trust profiles
- Credential attestation before offer
- Reduced re-screening for returning candidates

**4. Recruiter Efficiency**
- Automation that reduces cognitive load, not judgment
- Clear "next action" indicators
- Inbox-style approvals for hiring managers
- Assistive ranking, not black-box AI

### Who This Is For

- **SMB companies (50-500 employees)** who need enterprise-grade compliance without enterprise complexity
- **High-compliance industries** (finance, healthcare, government contractors) where hiring defensibility is non-negotiable
- **Organizations using Ledgoria** for background screening who want a seamlessly integrated recruiting workflow

### Competitive Position

We're not building another Greenhouse clone. We're building what comes next.

| Capability | Legacy ATS | Ledgoria |
|------------|-----------|------------|
| Compliance | Bolted on | Built in |
| Background checks | Integration | Native |
| Candidate identity | Assumed | Verified |
| Audit trail | Afterthought | Architecture |
| Adverse action | Manual | Automated workflow |

---

## Documentation

| Document | Description |
|----------|-------------|
| [Product Plan](docs/PRODUCT_PLAN.md) | Phased roadmap and feature prioritization |
| [Data Model](docs/DATA_MODEL.md) | Domain model with 12 bounded contexts |
| [Actors](docs/ACTORS.md) | System actors and permission matrix |
| [Use Cases](docs/USE_CASES.md) | 100+ use cases with mermaid diagrams |
| [CRUD Matrix](docs/CRUD_MATRIX.md) | Use case to data transaction mapping |

Detailed use cases: [`docs/use-cases/`](docs/use-cases/)

---

## Technical Foundation

- **Framework:** Ruby on Rails 8
- **Database:** PostgreSQL (production), SQLite (development)
- **Background Jobs:** Solid Queue
- **Real-time:** Turbo Streams + Solid Cable
- **Frontend:** Hotwire (Turbo + Stimulus), Bootstrap 5.3 (via CDN)
- **File Storage:** Active Storage (S3 in production)
- **Deployment:** AWS Elastic Beanstalk + CloudFormation (aligned with ledgoria_collect)

---

## Development Status

**Phase 1: Foundation MVP - COMPLETE**

| Sprint | Focus | Points | Status |
|--------|-------|--------|--------|
| Sprint 0 | Project Setup | 24 | Complete |
| Sprint 1 | Core Models & Multi-Tenancy | 40 | Complete |
| Sprint 2 | Job Requisitions | 52 | Complete |
| Sprint 3 | RBAC Admin & Reference Data | 67 | Complete |
| Sprint 4 | Pipeline & Workflow | 47 | Complete |
| Sprint 5 | Audit Trail & Dashboard | 45 | Complete |
| Sprint 6 | Career Site & Polish | 50 | Complete |
| **Total** | | **325** | **Done** |

**431 tests passing**

### Core Features Delivered

**Authentication & Authorization**
- [x] Multi-tenant organization support
- [x] User authentication (Devise)
- [x] Role-based access control (Pundit)
- [x] Admin UI for user/role management

**Job Requisitions**
- [x] Job CRUD with approval workflow
- [x] State machine: draft → pending_approval → open → closed
- [x] Department and hiring manager assignment
- [x] Reference data management with i18n

**Pipeline & Candidates**
- [x] Kanban pipeline view with drag-drop
- [x] Candidate profiles with PII encryption
- [x] Resume uploads (Active Storage)
- [x] Application 8-state workflow
- [x] Rejection workflow with reasons
- [x] Stage transitions with audit trail

**Compliance & Audit**
- [x] Immutable audit logs
- [x] Automatic change tracking (Auditable concern)
- [x] SLA alerts for stuck candidates
- [x] Recruiter dashboard with task queue

**Public Career Site**
- [x] Job listings with search/filters
- [x] Public application form (no account required)
- [x] Resume upload
- [x] Tokenized status tracking
- [x] Email notifications (confirmation, status updates)

### Next Phase (Phase 2)
- [ ] Interview scheduling with calendar integration
- [ ] Structured scorecards and feedback
- [ ] Customizable email templates
- [ ] Reporting and analytics

---

## License

Proprietary. All rights reserved.

---

*Built by people who believe hiring should be both human and defensible.*
