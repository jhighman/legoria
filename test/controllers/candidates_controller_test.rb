# frozen_string_literal: true

require "test_helper"

class CandidatesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @organization = organizations(:acme)
    @recruiter = users(:recruiter)
    @admin = users(:admin)
    @hiring_manager = users(:hiring_manager)
    @candidate = candidates(:john_doe)
  end

  # Authentication tests
  test "redirects to sign in when not authenticated" do
    get candidates_url
    assert_redirected_to new_user_session_path
  end

  # Index tests
  test "index displays candidates for recruiter" do
    sign_in @recruiter
    get candidates_url
    assert_response :success
    assert_select "h1", /Candidates/
  end

  test "index filters by search query" do
    sign_in @recruiter
    get candidates_url(q: "John")
    assert_response :success
  end

  test "index filters by source" do
    sign_in @recruiter
    get candidates_url(source: "career_site")
    assert_response :success
  end

  test "index sorts by name" do
    sign_in @recruiter
    get candidates_url(sort: "name_asc")
    assert_response :success
  end

  # Show tests
  test "show displays candidate profile" do
    sign_in @recruiter
    get candidate_url(@candidate)
    assert_response :success
    assert_select "h1", @candidate.full_name
  end

  test "hiring manager can view candidate with application to their job" do
    sign_in @hiring_manager
    # Use jane_smith who has an application to open_job (new_application fixture)
    jane = candidates(:jane_smith)
    job = jobs(:open_job)
    job.update!(hiring_manager: @hiring_manager)

    # The fixture already has jane_smith applied to open_job (new_application)
    # so we just need to verify the hiring manager can view

    get candidate_url(jane)
    assert_response :success
  end

  # New tests
  test "new displays form for recruiter" do
    sign_in @recruiter
    get new_candidate_url
    assert_response :success
    assert_select "form"
  end

  # Create tests
  test "create creates candidate for recruiter" do
    sign_in @recruiter

    assert_difference("Candidate.count") do
      post candidates_url, params: {
        candidate: {
          first_name: "New",
          last_name: "Candidate",
          email: "new@example.com"
        }
      }
    end

    assert_redirected_to candidate_url(Candidate.last)
    follow_redirect!
    assert_select "div", /Candidate was successfully created/
  end

  test "create with invalid params renders new" do
    sign_in @recruiter

    assert_no_difference("Candidate.count") do
      post candidates_url, params: {
        candidate: { first_name: "", last_name: "", email: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  # Edit tests
  test "edit displays form for recruiter" do
    sign_in @recruiter
    get edit_candidate_url(@candidate)
    assert_response :success
    assert_select "form"
  end

  # Update tests
  test "update modifies candidate" do
    sign_in @recruiter

    patch candidate_url(@candidate), params: {
      candidate: { first_name: "Updated" }
    }

    assert_redirected_to candidate_url(@candidate)
    @candidate.reload
    assert_equal "Updated", @candidate.first_name
  end

  test "update with invalid params renders edit" do
    sign_in @recruiter

    patch candidate_url(@candidate), params: {
      candidate: { first_name: "" }
    }

    assert_response :unprocessable_entity
  end

  # Destroy tests
  test "admin can archive candidate" do
    sign_in @admin

    delete candidate_url(@candidate)

    assert_redirected_to candidates_url
    @candidate.reload
    assert @candidate.discarded?
  end

  test "recruiter cannot archive candidate" do
    sign_in @recruiter

    delete candidate_url(@candidate)

    assert_redirected_to root_path
    @candidate.reload
    assert_not @candidate.discarded?
  end

  # Add note tests
  test "add_note creates note for candidate" do
    sign_in @recruiter

    assert_difference("CandidateNote.count") do
      post add_note_candidate_url(@candidate), params: {
        candidate_note: {
          content: "This is a test note",
          visibility: "team"
        }
      }
    end

    assert_redirected_to candidate_url(@candidate)
  end

  test "add_note with empty content fails" do
    sign_in @recruiter

    assert_no_difference("CandidateNote.count") do
      post add_note_candidate_url(@candidate), params: {
        candidate_note: {
          content: "",
          visibility: "team"
        }
      }
    end
  end
end
