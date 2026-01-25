# frozen_string_literal: true

require "test_helper"

class OrganizationBrandingTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    @branding = organization_brandings(:acme_branding)
  end

  test "valid branding" do
    assert @branding.valid?
  end

  test "validates hex color format" do
    @branding.primary_color = "invalid"
    assert_not @branding.valid?
    assert_includes @branding.errors[:primary_color], "must be a valid hex color"
  end

  test "allows valid hex colors" do
    @branding.primary_color = "#ff5733"
    assert @branding.valid?
  end

  test "validates URL format for social links" do
    @branding.linkedin_url = "not-a-url"
    assert_not @branding.valid?
    assert_includes @branding.errors[:linkedin_url], "must be a valid URL"
  end

  test "allows valid URLs" do
    @branding.linkedin_url = "https://linkedin.com/company/acme"
    assert @branding.valid?
  end

  test "validates meta title length" do
    @branding.meta_title = "a" * 80
    assert_not @branding.valid?
    assert @branding.errors[:meta_title].any?
  end

  test "validates meta description length" do
    @branding.meta_description = "a" * 200
    assert_not @branding.valid?
    assert @branding.errors[:meta_description].any?
  end

  test "rejects dangerous CSS" do
    @branding.custom_css = "body { background: url(javascript:alert(1)); }"
    assert_not @branding.valid?
    assert_includes @branding.errors[:custom_css], "contains potentially unsafe content"
  end

  test "css_variables returns color variables" do
    vars = @branding.css_variables
    assert_equal @branding.primary_color, vars["--brand-primary"]
    assert_equal @branding.font_family, vars["--brand-font-family"]
  end

  test "page_title returns formatted title" do
    assert_equal "Jobs | Careers at Acme Corp", @branding.page_title("Jobs")
  end

  test "social_links returns non-blank links" do
    @branding.linkedin_url = "https://linkedin.com/company/acme"
    @branding.twitter_url = ""
    links = @branding.social_links
    assert links.key?(:linkedin)
    assert_not links.key?(:twitter)
  end

  test "enabled_filters returns configured filters" do
    @branding.show_department_filter = true
    @branding.show_location_filter = false
    filters = @branding.enabled_filters
    assert_includes filters, :department
    assert_not_includes filters, :location
  end
end
