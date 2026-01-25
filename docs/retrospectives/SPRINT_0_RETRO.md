# Sprint 0 Retrospective

**Sprint:** 0 - Project Setup
**Date:** 2026-01-23
**Duration:** 1 session

---

## Summary

Sprint 0 established the development foundation for Ledgoria. The Rails 8 application was already initialized, so the sprint focused on configuring production infrastructure, adding development tooling, and preparing the test framework.

---

## What Went Well

### 1. Migrations ran successfully after fixes
All 28 database migrations for SA-01 through SA-05 executed cleanly once SQLite compatibility issues were resolved. The schema covers IAM, Organization, Jobs, Candidates, and Pipeline domains.

### 2. Modern tooling stack
- **Tailwind CSS v4** installed with hot reload via Procfile.dev
- **FactoryBot** configured with 9 comprehensive factory files
- **Active Storage** ready for S3 in production

### 3. Clean separation of environments
- Development/test use SQLite (zero setup required)
- Production configured for PostgreSQL + S3 (scalable)

### 4. Comprehensive seed data
The seed file creates a realistic test organization with:
- 6 users across 4 roles
- 7 departments
- 8 pipeline stages
- 11 rejection reasons
- 6 jobs (various statuses)
- 15 candidates with applications

---

## What Didn't Go Well

### 1. SQLite/PostgreSQL incompatibility caught late
**Issue:** Migrations used `jsonb` (PostgreSQL-specific) but development uses SQLite.
**Impact:** Required editing 10 migration files to change `jsonb` → `json`.
**Root cause:** Migrations were written assuming PostgreSQL everywhere.

### 2. Redundant indexes caused migration failures
**Issue:** `t.references` auto-creates an index, but explicit `add_index` calls duplicated them.
**Impact:** Had to remove 8 redundant index declarations.
**Root cause:** Didn't account for Rails' implicit index creation on references.

### 3. No model implementation yet
**Issue:** Seeds and factories reference models that don't exist.
**Impact:** `bin/rails db:seed` will fail until Sprint 1 completes.
**Root cause:** Sprint 0 scope was infrastructure-only; models are Sprint 1.

---

## Lessons Learned

| Lesson | Action |
|--------|--------|
| SQLite doesn't support `jsonb` | Use `json` type in migrations; document this in CLAUDE.md |
| `t.references` creates indexes automatically | Don't add explicit single-column indexes for foreign keys |
| Test migrations on target DB | Add CI step to test migrations on both SQLite and PostgreSQL |
| Seed files need models | Mark seed file as "requires Sprint 1" in comments |

---

## Metrics

| Metric | Value |
|--------|-------|
| Tasks completed | 6/6 (100%) |
| Migrations created | 28 |
| Migrations requiring fixes | 10 |
| Factory files created | 9 |
| Lines of seed data | 373 |
| Gems added | 5 (pg, tailwindcss-rails, factory_bot_rails, image_processing, aws-sdk-s3) |
| Files changed | 38 |
| Lines added | 1,517 |

---

## Action Items for Sprint 1

| # | Action | Owner | Priority |
|---|--------|-------|----------|
| 1 | Update CLAUDE.md with SQLite/PostgreSQL compatibility notes | Sprint 1 | High |
| 2 | Implement models so seeds can run | Sprint 1 | High |
| 3 | Add migration CI test for both databases | Sprint 1 | Medium |
| 4 | Create `Current` class for multi-tenancy | Sprint 1 | High |
| 5 | Consider adding `annotate` gem for model documentation | Sprint 1 | Low |

---

## Technical Debt Identified

| Item | Severity | Notes |
|------|----------|-------|
| Seeds require models | Low | Expected; will resolve in Sprint 1 |
| No auth yet | Low | Devise setup is Sprint 1 task |
| JSON vs JSONB | Low | JSON works for SQLite; consider JSONB migration for production later |

---

## Sprint 1 Readiness Checklist

- [x] Database schema created (28 tables)
- [x] Test framework configured (Minitest + FactoryBot)
- [x] CSS framework ready (Tailwind v4)
- [x] File upload infrastructure ready (Active Storage + S3)
- [x] CI pipeline exists (GitHub Actions)
- [x] Development seed data prepared
- [ ] Models implemented (Sprint 1)
- [ ] Authentication configured (Sprint 1)
- [ ] Multi-tenancy scoping (Sprint 1)

---

## Team Notes

Sprint 0 was completed in a single session. The existing Rails 8 scaffolding (from `rails new`) significantly reduced setup time. Key decisions made:

1. **Stick with SQLite for dev** - Zero configuration, fast tests
2. **PostgreSQL for production only** - Avoid JSONB dependency in dev
3. **Tailwind v4** - Latest version, different config than v3
4. **FactoryBot over fixtures** - More flexible for complex associations

---

## Next Sprint Preview

**Sprint 1: Core Models & Multi-Tenancy (Weeks 1-2)**

Focus areas:
- Implement all models for SA-01 (IAM) and SA-02 (Organization)
- Set up `Current.organization` for tenant scoping
- Add Devise authentication
- Create default scopes for multi-tenancy
- Write model tests with 100% validation coverage

Estimated points: 40
