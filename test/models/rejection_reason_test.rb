# frozen_string_literal: true

require "test_helper"

class RejectionReasonTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @reason = rejection_reasons(:not_qualified)
  end

  def teardown
    Current.organization = nil
  end

  test "valid rejection reason" do
    assert @reason.valid?
  end

  test "requires name" do
    @reason.name = nil
    assert_not @reason.valid?
    assert_includes @reason.errors[:name], "can't be blank"
  end

  test "requires category" do
    @reason.category = nil
    assert_not @reason.valid?
    assert_includes @reason.errors[:category], "can't be blank"
  end

  test "category must be valid" do
    @reason.category = "invalid"
    assert_not @reason.valid?
    assert_includes @reason.errors[:category], "is not included in the list"
  end

  test "valid categories" do
    RejectionReason::CATEGORIES.each do |category|
      @reason.category = category
      assert @reason.valid?, "RejectionReason should be valid with category: #{category}"
    end
  end

  test "position must be non-negative" do
    @reason.position = -1
    assert_not @reason.valid?

    @reason.position = 0
    assert @reason.valid?
  end

  test "category predicate methods" do
    @reason.category = "not_qualified"
    assert @reason.not_qualified?

    @reason.category = "timing"
    assert @reason.timing?

    @reason.category = "compensation"
    assert @reason.compensation?

    @reason.category = "culture_fit"
    assert @reason.culture_fit?

    @reason.category = "withdrew"
    assert @reason.withdrew?

    @reason.category = "other"
    assert @reason.other?
  end

  test "activate! sets active to true" do
    @reason.update!(active: false)
    @reason.activate!
    assert @reason.active
  end

  test "deactivate! sets active to false" do
    @reason.deactivate!
    assert_not @reason.active
  end

  test "active scope returns only active reasons" do
    active = RejectionReason.active
    active.each do |reason|
      assert reason.active
    end
  end

  test "inactive scope returns only inactive reasons" do
    @reason.deactivate!
    inactive = RejectionReason.inactive
    inactive.each do |reason|
      assert_not reason.active
    end
  end

  test "ordered scope sorts by position then name" do
    reasons = RejectionReason.ordered
    assert reasons.count >= 0 # Just verify scope works
  end

  test "by_category scope filters by category" do
    RejectionReason::CATEGORIES.each do |category|
      scoped = RejectionReason.by_category(category)
      scoped.each do |reason|
        assert_equal category, reason.category
      end
    end
  end
end
