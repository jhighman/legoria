# frozen_string_literal: true

require "test_helper"

class CandidateNoteTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @note = candidate_notes(:team_note)
    @private_note = candidate_notes(:private_note)
  end

  def teardown
    Current.organization = nil
  end

  test "valid candidate note" do
    assert @note.valid?
  end

  test "requires content" do
    @note.content = nil
    assert_not @note.valid?
    assert_includes @note.errors[:content], "can't be blank"
  end

  test "requires visibility" do
    @note.visibility = nil
    assert_not @note.valid?
  end

  test "validates visibility inclusion" do
    @note.visibility = "invalid"
    assert_not @note.valid?
    assert_includes @note.errors[:visibility], "is not included in the list"
  end

  test "valid visibilities" do
    CandidateNote::VISIBILITIES.each do |visibility|
      @note.visibility = visibility
      assert @note.valid?, "Should be valid with visibility: #{visibility}"
    end
  end

  test "private? returns true for private visibility" do
    assert @private_note.private?
    assert_not @note.private?
  end

  test "team_visible? returns true for team visibility" do
    assert @note.team_visible?
    assert_not @private_note.team_visible?
  end

  test "pin! sets pinned to true" do
    @note.pin!
    assert @note.pinned?
  end

  test "unpin! sets pinned to false" do
    @private_note.unpin!
    assert_not @private_note.pinned?
  end

  test "toggle_pin! toggles pinned status" do
    original = @note.pinned?
    @note.toggle_pin!
    assert_not_equal original, @note.pinned?
  end

  test "visibility_label returns readable label" do
    assert_equal "Team", @note.visibility_label
    assert_equal "Private", @private_note.visibility_label
  end

  test "author_name returns user full name" do
    assert_equal users(:recruiter).full_name, @note.author_name
  end

  test "excerpt truncates content" do
    @note.content = "A" * 200
    assert_equal 100, @note.excerpt(length: 100).length
  end

  test "visible_to scope includes team notes for any user" do
    user = users(:recruiter)
    visible = CandidateNote.visible_to(user)

    assert_includes visible, @note
  end

  test "visible_to scope includes private notes only for author" do
    author = users(:hiring_manager)
    other_user = users(:recruiter)

    author_visible = CandidateNote.visible_to(author)
    other_visible = CandidateNote.visible_to(other_user)

    assert_includes author_visible, @private_note
    assert_not_includes other_visible, @private_note
  end

  test "pinned scope returns only pinned notes" do
    CandidateNote.pinned.each do |note|
      assert note.pinned?
    end
  end

  test "pinned_first scope orders pinned notes first" do
    notes = CandidateNote.pinned_first
    pinned_notes = notes.select(&:pinned?)
    unpinned_notes = notes.reject(&:pinned?)

    if pinned_notes.any? && unpinned_notes.any?
      assert notes.index(pinned_notes.last) < notes.index(unpinned_notes.first)
    end
  end
end
