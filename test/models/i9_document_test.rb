# frozen_string_literal: true

require "test_helper"

class I9DocumentTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
    @passport = i9_documents(:us_passport)
    @drivers_license = i9_documents(:drivers_license)
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires list_type" do
    doc = I9Document.new(
      organization: @organization,
      i9_verification: i9_verifications(:verified),
      document_type: "us_passport"
    )
    assert_not doc.valid?
    assert_includes doc.errors[:list_type], "can't be blank"
  end

  test "requires document_type" do
    doc = I9Document.new(
      organization: @organization,
      i9_verification: i9_verifications(:verified),
      list_type: "list_a"
    )
    assert_not doc.valid?
    assert_includes doc.errors[:document_type], "can't be blank"
  end

  test "validates list_type inclusion" do
    doc = I9Document.new(
      organization: @organization,
      i9_verification: i9_verifications(:verified),
      list_type: "invalid",
      document_type: "us_passport"
    )
    assert_not doc.valid?
    assert_includes doc.errors[:list_type], "is not included in the list"
  end

  test "validates document_type matches list_type" do
    # List B document should not be valid for list_a
    doc = I9Document.new(
      organization: @organization,
      i9_verification: i9_verifications(:verified),
      list_type: "list_a",
      document_type: "drivers_license"
    )
    assert_not doc.valid?
    assert doc.errors[:document_type].any?
  end

  # Scopes
  test "list_a scope returns only list A documents" do
    assert_includes I9Document.list_a, @passport
    assert_not_includes I9Document.list_a, @drivers_license
  end

  test "list_b scope returns only list B documents" do
    assert_includes I9Document.list_b, @drivers_license
    assert_not_includes I9Document.list_b, @passport
  end

  test "verified_docs scope returns only verified documents" do
    assert_includes I9Document.verified_docs, @passport
    assert_not_includes I9Document.verified_docs, @drivers_license
  end

  # Verification
  test "verify! marks document as verified" do
    user = users(:admin)
    @drivers_license.verify!(user, notes: "Verified in person")

    @drivers_license.reload
    assert @drivers_license.verified?
    assert_equal user, @drivers_license.verified_by
    assert_not_nil @drivers_license.verified_at
    assert_equal "Verified in person", @drivers_license.verification_notes
  end

  test "unverify! removes verification" do
    @passport.unverify!

    @passport.reload
    assert_not @passport.verified?
    assert_nil @passport.verified_by
    assert_nil @passport.verified_at
  end

  # Status helpers
  test "verified? returns true for verified document" do
    assert @passport.verified?
  end

  test "expired? returns true for expired document" do
    @passport.update_column(:expiration_date, Date.yesterday)
    assert @passport.expired?
  end

  test "expires_soon? returns true for document expiring within days" do
    @passport.update_column(:expiration_date, 15.days.from_now.to_date)
    assert @passport.expires_soon?(30)
  end

  test "valid_document? requires verified and not expired" do
    assert @passport.valid_document?
  end

  test "valid_document? returns false if expired" do
    @passport.update_column(:expiration_date, Date.yesterday)
    assert_not @passport.valid_document?
  end

  # List type helpers
  test "list_a? returns true for list A document" do
    assert @passport.list_a?
  end

  test "list_b? returns true for list B document" do
    assert @drivers_license.list_b?
  end

  # Display helpers
  test "list_type_label returns human readable list type" do
    assert_equal "List A (Identity & Employment)", @passport.list_type_label
    assert_equal "List B (Identity Only)", @drivers_license.list_type_label
  end

  test "document_type_label returns human readable document type" do
    assert_equal "U.S. Passport", @passport.document_type_label
    assert_equal "Driver's License", @drivers_license.document_type_label
  end

  # Class methods
  test "documents_for_list_type returns correct documents" do
    list_a_docs = I9Document.documents_for_list_type("list_a")
    assert list_a_docs.key?("us_passport")
    assert_not list_a_docs.key?("drivers_license")
  end
end
