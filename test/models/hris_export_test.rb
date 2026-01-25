# frozen_string_literal: true

require "test_helper"

class HrisExportTest < ActiveSupport::TestCase
  def setup
    @export = hris_exports(:pending_export)
  end

  # Validations
  test "valid hris export" do
    assert @export.valid?
  end

  test "validates status inclusion" do
    @export.status = "invalid"
    assert_not @export.valid?
    assert_includes @export.errors[:status], "is not included in the list"
  end

  # Associations
  test "belongs to organization" do
    assert_respond_to @export, :organization
    assert_equal organizations(:acme), @export.organization
  end

  test "belongs to integration" do
    assert_respond_to @export, :integration
    assert_equal integrations(:workday_integration), @export.integration
  end

  test "belongs to application" do
    assert_respond_to @export, :application
  end

  test "belongs to candidate" do
    assert_respond_to @export, :candidate
  end

  test "belongs to exported_by user" do
    assert_respond_to @export, :exported_by
    assert_equal users(:admin), @export.exported_by
  end

  # Status methods
  test "pending? returns true for pending status" do
    assert @export.pending?
  end

  test "exporting? returns true for exporting status" do
    @export.status = "exporting"
    assert @export.exporting?
  end

  test "completed? returns true for completed status" do
    export = hris_exports(:completed_export)
    assert export.completed?
  end

  test "failed? returns true for failed status" do
    export = hris_exports(:failed_export)
    assert export.failed?
  end

  # Workflow methods
  test "start_export! transitions to exporting" do
    @export.start_export!(export_data: { first_name: "Test" })

    assert @export.exporting?
    assert_equal({ "first_name" => "Test" }, @export.export_data)
    assert_not_nil @export.exported_at
  end

  test "complete! transitions to completed" do
    @export.status = "exporting"
    @export.complete!(
      external_id: "emp_new_123",
      external_url: "https://hris.example.com/emp_new_123"
    )

    assert @export.completed?
    assert_equal "emp_new_123", @export.external_id
    assert_equal "https://hris.example.com/emp_new_123", @export.external_url
    assert_not_nil @export.confirmed_at
  end

  test "fail! transitions to failed" do
    @export.status = "exporting"
    @export.fail!(error_message: "API error")

    assert @export.failed?
    assert_equal "API error", @export.error_message
  end

  test "cancel! transitions to cancelled" do
    @export.cancel!

    assert @export.cancelled?
  end

  test "cancel! fails for completed exports" do
    export = hris_exports(:completed_export)
    result = export.cancel!

    assert_not result
    assert export.completed? # Status unchanged
  end

  test "retry! resets failed export to pending" do
    export = hris_exports(:failed_export)
    export.retry!

    assert export.pending?
    assert_nil export.error_message
  end

  # Scopes
  test "pending scope returns pending exports" do
    pending = HrisExport.pending
    assert pending.include?(@export)
    assert_not pending.include?(hris_exports(:completed_export))
  end

  test "completed scope returns completed exports" do
    completed = HrisExport.completed
    assert completed.include?(hris_exports(:completed_export))
    assert_not completed.include?(@export)
  end

  test "failed scope returns failed exports" do
    failed = HrisExport.failed
    assert failed.include?(hris_exports(:failed_export))
    assert_not failed.include?(@export)
  end
end
