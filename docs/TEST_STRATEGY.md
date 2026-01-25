# Ledgoria - Test Strategy

## Overview

This document defines the testing approach for Ledgoria. Given the compliance-first nature of the system, testing is critical for ensuring audit trail integrity, data security, and reliable hiring workflows.

---

## Testing Pyramid

```
                    ┌─────────────┐
                    │   System    │  ← 10% - Critical user journeys
                    │   Tests     │
                ┌───┴─────────────┴───┐
                │   Integration Tests  │  ← 30% - Service/controller tests
            ┌───┴─────────────────────┴───┐
            │       Unit Tests             │  ← 60% - Models, services, validators
            └─────────────────────────────┘
```

---

## Test Categories

### 1. Unit Tests (60% of test suite)

**Location:** `test/models/`, `test/services/`, `test/validators/`

**Coverage targets:**
- Models: 100% of validations, associations, scopes, callbacks
- Services: 100% of business logic paths
- Validators: 100% of custom validators

#### Model Tests

Each model test file should cover:

```ruby
# test/models/job_test.rb
class JobTest < ActiveSupport::TestCase
  # Validations
  test "requires title" do
    job = build(:job, title: nil)
    assert_not job.valid?
    assert_includes job.errors[:title], "can't be blank"
  end

  # Associations
  test "belongs to organization" do
    job = create(:job)
    assert_respond_to job, :organization
  end

  # Scopes
  test "open scope returns only open jobs" do
    open_job = create(:job, status: "open")
    draft_job = create(:job, status: "draft")

    assert_includes Job.open, open_job
    assert_not_includes Job.open, draft_job
  end

  # State machine transitions
  test "can transition from draft to pending_approval" do
    job = create(:job, status: "draft")
    assert job.submit_for_approval!
    assert_equal "pending_approval", job.status
  end

  # Callbacks
  test "sets opened_at when status changes to open" do
    job = create(:job, status: "pending_approval")
    job.approve!
    assert_not_nil job.opened_at
  end

  # Multi-tenancy
  test "scoped to organization by default" do
    org1 = create(:organization)
    org2 = create(:organization)
    job1 = create(:job, organization: org1)
    job2 = create(:job, organization: org2)

    Current.organization = org1
    assert_includes Job.all, job1
    assert_not_includes Job.all, job2
  end
end
```

#### Service Tests

```ruby
# test/services/applications/move_stage_service_test.rb
class Applications::MoveStageServiceTest < ActiveSupport::TestCase
  setup do
    @application = create(:application)
    @new_stage = create(:stage, organization: @application.organization)
    @user = create(:user, organization: @application.organization)
  end

  test "moves application to new stage" do
    result = Applications::MoveStageService.call(
      application: @application,
      stage: @new_stage,
      moved_by: @user
    )

    assert result.success?
    assert_equal @new_stage, @application.reload.current_stage
  end

  test "creates stage transition record" do
    assert_difference "StageTransition.count", 1 do
      Applications::MoveStageService.call(
        application: @application,
        stage: @new_stage,
        moved_by: @user
      )
    end
  end

  test "creates audit log entry" do
    assert_difference "AuditLog.count", 1 do
      Applications::MoveStageService.call(
        application: @application,
        stage: @new_stage,
        moved_by: @user
      )
    end
  end

  test "fails when moving to invalid stage" do
    invalid_stage = create(:stage) # Different org

    result = Applications::MoveStageService.call(
      application: @application,
      stage: invalid_stage,
      moved_by: @user
    )

    assert result.failure?
    assert_includes result.errors, "Stage not found"
  end
end
```

### 2. Integration Tests (30% of test suite)

**Location:** `test/integration/`, `test/controllers/`

**Coverage targets:**
- All controller actions
- API endpoints with authentication
- Cross-domain service interactions
- Background job processing

#### Controller Tests

```ruby
# test/controllers/jobs_controller_test.rb
class JobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = create(:organization)
    @user = create(:user, :recruiter, organization: @organization)
    sign_in @user
  end

  test "GET /jobs returns jobs for current organization only" do
    our_job = create(:job, organization: @organization)
    other_job = create(:job) # Different org

    get jobs_path

    assert_response :success
    assert_includes response.body, our_job.title
    assert_not_includes response.body, other_job.title
  end

  test "POST /jobs creates job with audit trail" do
    job_params = attributes_for(:job)

    assert_difference ["Job.count", "AuditLog.count"], 1 do
      post jobs_path, params: { job: job_params }
    end

    assert_redirected_to job_path(Job.last)

    audit = AuditLog.last
    assert_equal "job.created", audit.action
    assert_equal @user.id, audit.user_id
  end

  test "unauthorized user cannot access jobs" do
    sign_out @user
    get jobs_path
    assert_redirected_to new_session_path
  end
end
```

#### API Tests

```ruby
# test/integration/api/v1/jobs_api_test.rb
class Api::V1::JobsApiTest < ActionDispatch::IntegrationTest
  setup do
    @organization = create(:organization)
    @api_key = create(:api_key, organization: @organization)
  end

  test "GET /api/v1/jobs with valid API key" do
    job = create(:job, organization: @organization)

    get "/api/v1/jobs", headers: api_headers(@api_key)

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["data"].length
  end

  test "GET /api/v1/jobs without API key returns 401" do
    get "/api/v1/jobs"
    assert_response :unauthorized
  end

  test "rate limiting enforced" do
    101.times do
      get "/api/v1/jobs", headers: api_headers(@api_key)
    end

    assert_response :too_many_requests
  end

  private

  def api_headers(api_key)
    { "Authorization" => "Bearer #{api_key.token}" }
  end
end
```

### 3. System Tests (10% of test suite)

**Location:** `test/system/`

**Coverage targets:**
- Critical user journeys (happy paths)
- JavaScript interactions
- Turbo/Stimulus functionality

#### Critical Journeys to Test

| Journey | Priority | Test File |
|---------|----------|-----------|
| Recruiter creates job | P0 | `jobs_test.rb` |
| Candidate applies for job | P0 | `career_site_test.rb` |
| Move candidate through pipeline | P0 | `pipeline_test.rb` |
| Reject candidate with reason | P0 | `rejections_test.rb` |
| Approve job requisition | P1 | `approvals_test.rb` |
| User login/logout | P1 | `authentication_test.rb` |

```ruby
# test/system/pipeline_test.rb
class PipelineTest < ApplicationSystemTestCase
  setup do
    @organization = create(:organization)
    @recruiter = create(:user, :recruiter, organization: @organization)
    @job = create(:job, :open, organization: @organization)
    @application = create(:application, job: @job)

    sign_in @recruiter
  end

  test "move candidate to next stage via drag and drop" do
    next_stage = @job.job_stages.second.stage

    visit job_pipeline_path(@job)

    # Find candidate card and target stage column
    candidate_card = find("[data-application-id='#{@application.id}']")
    target_column = find("[data-stage-id='#{next_stage.id}']")

    # Drag and drop
    candidate_card.drag_to(target_column)

    # Verify move
    assert_selector "[data-stage-id='#{next_stage.id}'] [data-application-id='#{@application.id}']"

    # Verify persistence
    assert_equal next_stage, @application.reload.current_stage
  end

  test "reject candidate with reason" do
    visit job_pipeline_path(@job)

    within("[data-application-id='#{@application.id}']") do
      click_button "Actions"
      click_link "Reject"
    end

    within("#rejection-modal") do
      select "Not qualified", from: "Rejection reason"
      fill_in "Notes", with: "Does not meet minimum requirements"
      click_button "Reject Candidate"
    end

    assert_text "Candidate rejected"
    assert_equal "rejected", @application.reload.status
  end
end
```

---

## Test Infrastructure

### Factories (FactoryBot)

**Location:** `test/factories/`

```ruby
# test/factories/organizations.rb
FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:subdomain) { |n| "org#{n}" }
    timezone { "America/New_York" }

    trait :with_default_stages do
      after(:create) do |org|
        Stage::DEFAULT_STAGES.each_with_index do |(name, type), index|
          create(:stage, organization: org, name: name, stage_type: type, position: index)
        end
      end
    end
  end
end

# test/factories/users.rb
FactoryBot.define do
  factory :user do
    organization
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { "Test" }
    last_name { "User" }
    password { "password123" }

    trait :admin do
      after(:create) do |user|
        admin_role = create(:role, :admin, organization: user.organization)
        create(:user_role, user: user, role: admin_role)
      end
    end

    trait :recruiter do
      after(:create) do |user|
        recruiter_role = create(:role, :recruiter, organization: user.organization)
        create(:user_role, user: user, role: recruiter_role)
      end
    end

    trait :hiring_manager do
      after(:create) do |user|
        hm_role = create(:role, :hiring_manager, organization: user.organization)
        create(:user_role, user: user, role: hm_role)
      end
    end
  end
end

# test/factories/jobs.rb
FactoryBot.define do
  factory :job do
    organization
    sequence(:title) { |n| "Software Engineer #{n}" }
    description { "Job description" }
    location { "New York, NY" }
    location_type { "hybrid" }
    employment_type { "full_time" }
    status { "draft" }

    trait :open do
      status { "open" }
      opened_at { Time.current }
    end

    trait :with_stages do
      after(:create) do |job|
        job.organization.stages.each_with_index do |stage, index|
          create(:job_stage, job: job, stage: stage, position: index)
        end
      end
    end
  end
end

# test/factories/applications.rb
FactoryBot.define do
  factory :application do
    organization { job.organization }
    job { association :job, :open, :with_stages }
    candidate { association :candidate, organization: job.organization }
    current_stage { job.job_stages.first.stage }
    status { "active" }
    source_type { "direct_apply" }
    applied_at { Time.current }
    last_activity_at { Time.current }
  end
end
```

### Test Helpers

**Location:** `test/support/`

```ruby
# test/support/authentication_helper.rb
module AuthenticationHelper
  def sign_in(user)
    post sessions_path, params: {
      email: user.email,
      password: "password123"
    }
    follow_redirect! if response.redirect?
  end

  def sign_out
    delete session_path
  end

  def api_sign_in(api_key)
    { "Authorization" => "Bearer #{api_key.token}" }
  end
end

# test/support/multi_tenancy_helper.rb
module MultiTenancyHelper
  def with_organization(organization)
    Current.organization = organization
    yield
  ensure
    Current.reset
  end
end

# test/support/audit_helper.rb
module AuditHelper
  def assert_audited(action:, auditable:)
    audit = AuditLog.find_by(action: action, auditable: auditable)
    assert audit, "Expected audit log for #{action} on #{auditable.class}##{auditable.id}"
    audit
  end
end
```

### Test Configuration

```ruby
# test/test_helper.rb
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"

# Load support files
Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include AuthenticationHelper
  include MultiTenancyHelper
  include AuditHelper

  parallelize(workers: :number_of_processors)

  setup do
    Current.reset
  end

  teardown do
    Current.reset
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelper
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1000]

  include AuthenticationHelper

  def sign_in(user)
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"
    assert_text "Dashboard"
  end
end
```

---

## Compliance-Critical Tests

These tests are **mandatory** and must pass before any release.

### Audit Trail Integrity

```ruby
# test/compliance/audit_trail_test.rb
class AuditTrailTest < ActiveSupport::TestCase
  test "stage transitions are immutable" do
    transition = create(:stage_transition)

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      transition.update!(notes: "Changed")
    end
  end

  test "audit logs are immutable" do
    audit = create(:audit_log)

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      audit.update!(action: "changed")
    end
  end

  test "audit logs cannot be destroyed" do
    audit = create(:audit_log)

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      audit.destroy
    end
  end

  test "all state changes create audit entries" do
    application = create(:application)
    new_stage = create(:stage, organization: application.organization)
    user = create(:user, organization: application.organization)

    Applications::MoveStageService.call(
      application: application,
      stage: new_stage,
      moved_by: user
    )

    assert_audited(action: "application.stage_changed", auditable: application)
  end
end
```

### Multi-Tenancy Isolation

```ruby
# test/compliance/multi_tenancy_test.rb
class MultiTenancyTest < ActiveSupport::TestCase
  setup do
    @org1 = create(:organization)
    @org2 = create(:organization)
  end

  test "cannot access jobs from another organization" do
    job1 = create(:job, organization: @org1)
    job2 = create(:job, organization: @org2)

    with_organization(@org1) do
      assert_includes Job.all, job1
      assert_not_includes Job.all, job2
    end
  end

  test "cannot move candidate to job in another organization" do
    candidate = create(:candidate, organization: @org1)
    job = create(:job, organization: @org2)

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:application, candidate: candidate, job: job)
    end
  end

  test "cannot assign user from another organization" do
    job = create(:job, organization: @org1)
    user = create(:user, organization: @org2)

    assert_raises(ActiveRecord::RecordInvalid) do
      job.update!(hiring_manager: user)
    end
  end
end
```

### Data Encryption

```ruby
# test/compliance/encryption_test.rb
class EncryptionTest < ActiveSupport::TestCase
  test "candidate email is encrypted at rest" do
    candidate = create(:candidate, email: "test@example.com")

    # Read raw value from database
    raw = ActiveRecord::Base.connection.select_value(
      "SELECT email FROM candidates WHERE id = #{candidate.id}"
    )

    assert_not_equal "test@example.com", raw
    assert_equal "test@example.com", candidate.email
  end

  test "candidate phone is encrypted at rest" do
    candidate = create(:candidate, phone: "555-123-4567")

    raw = ActiveRecord::Base.connection.select_value(
      "SELECT phone FROM candidates WHERE id = #{candidate.id}"
    )

    assert_not_equal "555-123-4567", raw
    assert_equal "555-123-4567", candidate.phone
  end
end
```

---

## Coverage Requirements

### Minimum Coverage Targets

| Category | Target | Enforcement |
|----------|--------|-------------|
| Overall | 90% | CI blocks merge below threshold |
| Models | 100% | Required for all validations/scopes |
| Services | 95% | Required for all business logic |
| Controllers | 85% | Required for all actions |
| Compliance tests | 100% | Must all pass |

### Coverage Configuration

```ruby
# test/test_helper.rb (add to top)
require "simplecov"
SimpleCov.start "rails" do
  minimum_coverage 90
  minimum_coverage_by_file 80

  add_filter "/test/"
  add_filter "/config/"

  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services", "app/services"
  add_group "Policies", "app/policies"

  # Fail build if coverage drops
  refuse_coverage_drop
end
```

---

## CI Pipeline Integration

```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.5
          bundler-cache: true

      - name: Setup database
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/ledgoria_test
        run: |
          bin/rails db:create
          bin/rails db:schema:load

      - name: Run unit tests
        run: bin/rails test

      - name: Run system tests
        run: bin/rails test:system

      - name: Run compliance tests
        run: bin/rails test test/compliance/

      - name: Check coverage
        run: |
          if [ $(cat coverage/.last_run.json | jq '.result.covered_percent') -lt 90 ]; then
            echo "Coverage below 90%"
            exit 1
          fi

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

---

## Test Data Management

### Seed Data for Development

```ruby
# db/seeds/development.rb
# Creates realistic test data for local development

org = Organization.create!(
  name: "Acme Corp",
  subdomain: "acme",
  timezone: "America/New_York"
)

# Create default stages
Stage::DEFAULT_STAGES.each_with_index do |(name, type), i|
  Stage.create!(organization: org, name: name, stage_type: type, position: i)
end

# Create users
admin = User.create!(
  organization: org,
  email: "admin@acme.test",
  password: "password123",
  first_name: "Admin",
  last_name: "User"
)
# ... more seed data
```

### Test Data Cleanup

```ruby
# test/support/database_cleaner.rb
require "database_cleaner/active_record"

DatabaseCleaner.strategy = :transaction

class ActiveSupport::TestCase
  setup do
    DatabaseCleaner.start
  end

  teardown do
    DatabaseCleaner.clean
  end
end
```

---

## Running Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/job_test.rb

# Run specific test by line number
bin/rails test test/models/job_test.rb:42

# Run system tests
bin/rails test:system

# Run compliance tests only
bin/rails test test/compliance/

# Run with verbose output
bin/rails test -v

# Run in parallel (default)
bin/rails test

# Run single-threaded (for debugging)
PARALLEL_WORKERS=1 bin/rails test

# Run with coverage report
COVERAGE=true bin/rails test
```

---

## Current Status

**Phase 1 MVP Complete: 431 tests passing**

| Category | Count | Notes |
|----------|-------|-------|
| Model tests | 180+ | All models with validations, associations, scopes |
| Controller tests | 150+ | All CRUD actions, authorization |
| Service tests | 30+ | MoveStageService, RejectionService |
| Mailer tests | 15+ | JobApplicationMailer |
| Policy tests | 40+ | Pundit policies |
| Integration tests | 20+ | Multi-step workflows |

### Completed Items

1. [x] Create initial factory definitions (FactoryBot)
2. [x] Write compliance test suite (audit trail, multi-tenancy, encryption)
3. [x] Create test helpers for authentication
4. [x] Multi-tenant scoping tests for all models
5. [x] Immutability tests for AuditLog and StageTransition

### Next Steps (Phase 2)

1. [ ] Set up SimpleCov with coverage thresholds
2. [ ] Set up GitHub Actions workflow
3. [ ] Add system tests for critical journeys
4. [ ] Interview scheduling tests
5. [ ] Scorecard and feedback tests
