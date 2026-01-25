# frozen_string_literal: true

require "test_helper"

module Admin
  class AuditLogsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    def setup
      @organization = organizations(:acme)
      @admin = users(:admin)
      @recruiter = users(:recruiter)
    end

    # Authentication and authorization
    test "redirects to sign in when not authenticated" do
      get admin_audit_logs_url
      assert_redirected_to new_user_session_path
    end

    test "non-admin cannot access audit logs" do
      sign_in @recruiter
      get admin_audit_logs_url
      assert_redirected_to root_path
      follow_redirect!
      assert_select "div", /administrator/
    end

    # Index tests
    test "admin can view audit logs index" do
      sign_in @admin
      get admin_audit_logs_url
      assert_response :success
      assert_select "h1", /Audit Logs/
    end

    test "index displays audit log entries" do
      sign_in @admin
      # Create an audit log entry
      Current.organization = @organization
      Current.user = @admin
      AuditLog.log!(action: "test.action", auditable: jobs(:open_job))
      Current.reset

      get admin_audit_logs_url
      assert_response :success
    end

    test "index filters by action" do
      sign_in @admin
      get admin_audit_logs_url(action_filter: "job.created")
      assert_response :success
    end

    test "index filters by user" do
      sign_in @admin
      get admin_audit_logs_url(user_id: @admin.id)
      assert_response :success
    end

    test "index filters by auditable type" do
      sign_in @admin
      get admin_audit_logs_url(auditable_type: "Job")
      assert_response :success
    end

    test "index filters by date range" do
      sign_in @admin
      get admin_audit_logs_url(
        start_date: 1.week.ago.to_date,
        end_date: Date.today
      )
      assert_response :success
    end

    # Show tests
    test "admin can view audit log details" do
      sign_in @admin
      audit_log = audit_logs(:job_created)
      get admin_audit_log_url(audit_log)
      assert_response :success
      assert_select "h5", /Audit Log Details/
    end

    test "show displays changes if present" do
      sign_in @admin
      audit_log = audit_logs(:job_updated)
      get admin_audit_log_url(audit_log)
      assert_response :success
    end

    test "show displays metadata if present" do
      sign_in @admin
      audit_log = audit_logs(:job_created)
      get admin_audit_log_url(audit_log)
      assert_response :success
    end
  end
end
