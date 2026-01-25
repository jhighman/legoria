# Sprint 1 Retrospective: Core Models & Multi-Tenancy

**Sprint Duration:** 2 weeks
**Sprint Goal:** Establish multi-tenancy foundation and core IAM/Organization models
**Sprint Status:** Complete

## Summary

Sprint 1 successfully implemented the core data models and multi-tenancy foundation for the Ledgoria ATS. All 10 planned tasks were completed with 80 model tests passing.

## Deliverables

### Models Implemented (11)
1. **Current** - Thread-safe request-scoped storage for multi-tenancy context
2. **Organization** - Core tenant model with settings, plans, and default data callbacks
3. **User** - Devise-powered authentication with role-based access
4. **Role** - System and custom roles with JSON permissions
5. **Permission** - Granular resource/action permissions
6. **RolePermission** - Join table for role-permission associations
7. **UserRole** - Join table for user-role assignments
8. **Department** - Hierarchical organizational structure
9. **Stage** - Application pipeline stages with types
10. **RejectionReason** - Categorized rejection reasons

### Concerns Implemented (2)
1. **OrganizationScoped** - Automatic tenant scoping with default_scope and before_validation
2. **Discardable** - Soft delete functionality with kept/discarded scopes

### Policies Implemented (5)
1. **ApplicationPolicy** - Base policy with org-scoped authorization helpers
2. **OrganizationPolicy** - Admin-only management
3. **UserPolicy** - Admin and self-management permissions
4. **RolePolicy** - Admin-only, protects system roles
5. **DepartmentPolicy** - Admin and department manager access
6. **StagePolicy** - Admin-only stage management

### Testing
- **80 model tests** with **183 assertions**
- **6 fixture files** covering all Sprint 1 models
- Tests run in parallel using 8 processes

## What Went Well

1. **Devise Integration** - The authentication setup went smoothly with appropriate modules selected for an enterprise ATS
2. **Multi-Tenancy Pattern** - The Current context + OrganizationScoped concern provides clean, automatic tenant isolation
3. **Pundit Authorization** - Base policy with helper methods provides good foundation for role-based access
4. **Test Coverage** - Comprehensive model tests catch issues early

## Challenges & Solutions

### 1. Minitest 6.0.1 Incompatibility
**Problem:** Ruby 3.4.5 bundled minitest 6.0.1 which has breaking API changes incompatible with Rails 8's test runner.
**Solution:** Pinned minitest to `~> 5.25` in Gemfile.
**Lesson:** Always check gem compatibility when using cutting-edge Ruby versions.

### 2. Fixture Naming Conflicts
**Problem:** Role model had both a `permissions` JSON column and a `has_many :permissions` association, causing Rails fixtures to misinterpret the YAML.
**Solution:** Renamed the association to `has_many :linked_permissions, source: :permission`.
**Lesson:** Avoid naming associations the same as column names, especially with JSON columns.

### 3. Organization Active Column Missing
**Problem:** Test fixtures used `active: true` but Organization uses `discarded_at` (Discardable concern) for soft delete.
**Solution:** Updated fixtures and tests to use `discarded_at` and Discardable methods (`kept?`, `discard!`).
**Lesson:** Always verify actual database schema before writing fixtures.

### 4. JSON in Fixtures
**Problem:** YAML fixtures interpreted Ruby hashes as association data for JSON columns.
**Solution:** Use JSON string format in fixtures: `permissions: '{"key": ["value"]}'`.
**Lesson:** Serialize JSON column values as strings in fixtures.

## Metrics

| Metric | Value |
|--------|-------|
| Models Created | 11 |
| Concerns Created | 2 |
| Policies Created | 6 |
| Tests Written | 80 |
| Assertions | 183 |
| Files Changed | 35 |
| Lines Added | 2,428 |

## Technical Decisions Made

1. **Permissions Storage**: Using JSON column on Role for quick permission checks, with RolePermission table available for more complex permission management.

2. **Devise Modules**: Selected enterprise-appropriate modules:
   - `database_authenticatable` - Email/password auth
   - `recoverable` - Password reset
   - `rememberable` - Remember me
   - `validatable` - Email/password validation
   - `trackable` - Sign-in tracking
   - `lockable` - Account locking after failed attempts
   - `confirmable` - Email confirmation (required in production only)

3. **Soft Delete**: Organization uses Discardable concern; Users use `active` boolean for account state.

4. **Department Hierarchy**: Self-referential parent/child with depth limiting via validation.

## Sprint 2 Preparation

### Dependencies Ready
- Multi-tenancy foundation in place
- User authentication working
- Role-based authorization framework ready

### Next Sprint Focus (SA-03: Job Requisition)
- Job model with status workflow
- JobApproval for requisition approvals
- JobStage linking jobs to pipeline stages
- Department integration

### Considerations for Sprint 2
1. Job model needs department association - ready to uncomment `has_many :jobs` in Department
2. Will need JobPolicy with hiring_manager permissions
3. Consider approval workflow with state machine pattern

## Action Items for Next Sprint

1. Create Job, JobApproval, JobStage models
2. Add job board posting model
3. Implement job status workflow
4. Add job-specific Pundit policies
5. Write comprehensive job model tests

---

*Retrospective completed: Sprint 1*
*Next up: Sprint 2 - Job Requisition Management*
