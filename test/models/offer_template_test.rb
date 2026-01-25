# frozen_string_literal: true

require "test_helper"

class OfferTemplateTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @template = offer_templates(:standard_template)
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

  test "requires body" do
    @template.body = nil
    assert_not @template.valid?
    assert_includes @template.errors[:body], "can't be blank"
  end

  test "validates template_type inclusion" do
    @template.template_type = "invalid"
    assert_not @template.valid?
    assert_includes @template.errors[:template_type], "is not included in the list"
  end

  # Type helpers
  test "standard? returns true for standard templates" do
    assert @template.standard?
  end

  test "executive? returns true for executive templates" do
    assert offer_templates(:executive_template).executive?
  end

  # Template rendering
  test "render substitutes variables" do
    content = @template.render(
      candidate_name: "John Doe",
      job_title: "Product Manager",
      salary: "$120,000"
    )
    assert_includes content, "John Doe"
    assert_includes content, "Product Manager"
    assert_includes content, "$120,000"
  end

  test "render_subject substitutes variables" do
    subject = @template.render_subject(job_title: "Engineer", company_name: "Acme Corp")
    assert_includes subject, "Engineer"
    assert_includes subject, "Acme Corp"
  end

  # Duplication
  test "duplicate creates copy with modified name" do
    new_template = @template.duplicate
    assert_equal "#{@template.name} (Copy)", new_template.name
    assert_not new_template.is_default?
  end

  # Activation
  test "deactivate! sets active to false" do
    @template.deactivate!
    assert_not @template.reload.active?
  end

  test "activate! sets active to true" do
    inactive = offer_templates(:inactive_template)
    inactive.activate!
    assert inactive.reload.active?
  end

  # Scopes
  test "active scope returns only active templates" do
    active = OfferTemplate.active
    active.each { |t| assert t.active? }
  end

  test "by_type scope filters by template type" do
    standard = OfferTemplate.by_type("standard")
    standard.each { |t| assert t.standard? }
  end
end
