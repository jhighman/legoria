# frozen_string_literal: true

require "test_helper"

class AutomationRuleTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    @user = users(:admin)
    Current.organization = @organization
    Current.user = @user
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires name" do
    rule = AutomationRule.new(
      organization: @organization,
      created_by: @user,
      rule_type: "knockout_question",
      trigger_event: "application_created",
      conditions: { question_id: 1 },
      actions: [{ type: "reject" }]
    )
    assert_not rule.valid?
    assert_includes rule.errors[:name], "can't be blank"
  end

  test "requires rule_type" do
    rule = AutomationRule.new(
      organization: @organization,
      created_by: @user,
      name: "Test Rule",
      trigger_event: "application_created",
      conditions: { question_id: 1 },
      actions: [{ type: "reject" }]
    )
    assert_not rule.valid?
    assert_includes rule.errors[:rule_type], "can't be blank"
  end

  test "validates rule_type inclusion" do
    rule = automation_rules(:knockout_rule)
    rule.rule_type = "invalid"
    assert_not rule.valid?
    assert_includes rule.errors[:rule_type], "is not included in the list"
  end

  test "requires trigger_event" do
    rule = AutomationRule.new(
      organization: @organization,
      created_by: @user,
      name: "Test Rule",
      rule_type: "knockout_question",
      conditions: { question_id: 1 },
      actions: [{ type: "reject" }]
    )
    assert_not rule.valid?
    assert_includes rule.errors[:trigger_event], "can't be blank"
  end

  test "validates trigger_event inclusion" do
    rule = automation_rules(:knockout_rule)
    rule.trigger_event = "invalid"
    assert_not rule.valid?
    assert_includes rule.errors[:trigger_event], "is not included in the list"
  end

  test "requires conditions" do
    rule = AutomationRule.new(
      organization: @organization,
      created_by: @user,
      name: "Test Rule",
      rule_type: "knockout_question",
      trigger_event: "application_created",
      actions: [{ type: "reject" }]
    )
    assert_not rule.valid?
    assert_includes rule.errors[:conditions], "can't be blank"
  end

  test "requires actions" do
    rule = AutomationRule.new(
      organization: @organization,
      created_by: @user,
      name: "Test Rule",
      rule_type: "knockout_question",
      trigger_event: "application_created",
      conditions: { question_id: 1 }
    )
    assert_not rule.valid?
    assert_includes rule.errors[:actions], "can't be blank"
  end

  # Scopes
  test "active scope returns active rules" do
    assert_includes AutomationRule.active, automation_rules(:knockout_rule)
    assert_not_includes AutomationRule.active, automation_rules(:inactive_rule)
  end

  test "inactive scope returns inactive rules" do
    assert_includes AutomationRule.inactive, automation_rules(:inactive_rule)
    assert_not_includes AutomationRule.inactive, automation_rules(:knockout_rule)
  end

  test "by_type scope filters by rule_type" do
    knockout_rules = AutomationRule.by_type("knockout_question")
    assert_includes knockout_rules, automation_rules(:knockout_rule)
    assert_not_includes knockout_rules, automation_rules(:high_score_advance)
  end

  test "by_trigger scope filters by trigger_event" do
    create_rules = AutomationRule.by_trigger("application_created")
    assert_includes create_rules, automation_rules(:knockout_rule)
    assert_not_includes create_rules, automation_rules(:high_score_advance)
  end

  test "for_job scope filters by job_id" do
    job_rules = AutomationRule.for_job(jobs(:draft_job).id)
    assert_includes job_rules, automation_rules(:knockout_rule)
  end

  test "org_wide scope returns rules without job" do
    org_wide_rules = AutomationRule.org_wide
    assert_includes org_wide_rules, automation_rules(:high_score_advance)
    assert_not_includes org_wide_rules, automation_rules(:knockout_rule)
  end

  # Activate/deactivate
  test "activate sets active to true" do
    rule = automation_rules(:inactive_rule)
    assert_not rule.active?
    rule.activate!
    assert rule.active?
  end

  test "deactivate sets active to false" do
    rule = automation_rules(:knockout_rule)
    assert rule.active?
    rule.deactivate!
    assert_not rule.active?
  end

  # Evaluation
  test "evaluate returns false for inactive rules" do
    rule = automation_rules(:inactive_rule)
    application = applications(:active_application)
    assert_not rule.evaluate(application)
  end

  test "evaluate returns false for wrong job" do
    rule = automation_rules(:knockout_rule)
    # Create an application for a different job
    other_job = jobs(:open_job)
    other_application = Application.new(
      organization: @organization,
      job: other_job,
      candidate: candidates(:john_doe),
      current_stage: stages(:applied),
      source_type: "career_site"
    )
    assert_not rule.evaluate(other_application)
  end
end
