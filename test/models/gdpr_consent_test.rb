# frozen_string_literal: true

require "test_helper"

class GdprConsentTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @consent = gdpr_consents(:data_processing_consent)
  end

  def teardown
    Current.organization = nil
  end

  test "valid consent" do
    assert @consent.valid?
  end

  test "requires consent_type" do
    @consent.consent_type = nil
    assert_not @consent.valid?
    assert_includes @consent.errors[:consent_type], "can't be blank"
  end

  test "validates consent_type inclusion" do
    @consent.consent_type = "invalid"
    assert_not @consent.valid?
    assert_includes @consent.errors[:consent_type], "is not included in the list"
  end

  # Type helpers
  test "data_processing? returns true for data_processing consents" do
    assert @consent.data_processing?
  end

  test "marketing? returns true for marketing consents" do
    assert gdpr_consents(:marketing_consent).marketing?
  end

  # Status helpers
  test "active? returns true for granted and not withdrawn" do
    assert @consent.active?
  end

  test "withdrawn? returns true when withdrawn_at is set" do
    assert gdpr_consents(:withdrawn_consent).withdrawn?
  end

  # Actions
  test "grant! sets granted and timestamps" do
    new_consent = GdprConsent.new(
      organization: @organization,
      candidate: candidates(:jane_smith),
      consent_type: "third_party_sharing"
    )
    new_consent.save!
    new_consent.grant!(ip_address: "1.2.3.4", method: "portal")

    assert new_consent.granted?
    assert new_consent.granted_at.present?
    assert_equal "1.2.3.4", new_consent.ip_address
  end

  test "withdraw! sets withdrawn_at" do
    @consent.withdraw!
    assert @consent.withdrawn?
    assert_not @consent.granted?
  end

  # Display helpers
  test "consent_type_label returns formatted type" do
    assert_equal "Data Processing", @consent.consent_type_label
  end

  test "status_label returns Active for active consents" do
    assert_equal "Active", @consent.status_label
  end

  test "status_label returns Withdrawn for withdrawn consents" do
    assert_equal "Withdrawn", gdpr_consents(:withdrawn_consent).status_label
  end

  # Class methods
  test "has_active_consent? checks for active consent" do
    assert GdprConsent.has_active_consent?(candidates(:john_doe), "data_processing")
    assert_not GdprConsent.has_active_consent?(candidates(:jane_smith), "data_processing")
  end

  # Scopes
  test "active scope returns granted and not withdrawn" do
    active = GdprConsent.active
    active.each { |c| assert c.active? }
  end

  test "granted scope returns only granted consents" do
    granted = GdprConsent.granted
    granted.each { |c| assert c.granted? }
  end
end
