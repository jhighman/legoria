# frozen_string_literal: true

require "test_helper"

class ScorecardTemplateTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @template = scorecard_templates(:default_template)
  end

  def teardown
    Current.organization = nil
  end

  test "valid template" do
    assert @template.valid?
  end

  test "requires name" do
    @template.name = nil
    assert_not @template.valid?
    assert_includes @template.errors[:name], "can't be blank"
  end

  test "validates interview_type inclusion" do
    @template.interview_type = "invalid_type"
    assert_not @template.valid?
    assert_includes @template.errors[:interview_type], "is not included in the list"
  end

  test "allows blank interview_type" do
    @template.interview_type = nil
    assert @template.valid?
  end

  test "active scope returns active templates" do
    templates = ScorecardTemplate.active
    templates.each { |t| assert t.active? }
  end

  test "defaults scope returns default templates" do
    templates = ScorecardTemplate.defaults
    templates.each { |t| assert t.is_default? }
  end

  test "for_job scope filters by job" do
    job = jobs(:open_job)
    templates = ScorecardTemplate.for_job(job.id)
    templates.each do |t|
      assert t.job_id == job.id || t.job_id.nil?
    end
  end

  test "add_section creates new section" do
    assert_difference -> { @template.scorecard_template_sections.count }, 1 do
      @template.add_section(name: "New Section", section_type: "custom")
    end
  end

  test "duplicate creates copy with new name" do
    assert_difference -> { ScorecardTemplate.count }, 1 do
      copy = @template.duplicate
      assert_includes copy.name, "Copy"
      assert_not copy.is_default?
    end
  end

  test "section_count returns correct count" do
    assert_equal @template.scorecard_template_sections.count, @template.section_count
  end

  test "item_count returns correct count" do
    assert_equal @template.scorecard_template_items.count, @template.item_count
  end

  test "scope_description for organization-wide template" do
    @template.job_id = nil
    @template.stage_id = nil
    @template.interview_type = nil
    assert_equal "Organization-wide", @template.scope_description
  end

  test "scope_description includes job when set" do
    template = scorecard_templates(:job_specific_template)
    assert_includes template.scope_description, "Job:"
  end
end
