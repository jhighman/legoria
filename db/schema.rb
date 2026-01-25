# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_25_110233) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "adverse_actions", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "application_id", null: false
    t.integer "initiated_by_id", null: false
    t.string "action_type", null: false
    t.string "status", default: "draft", null: false
    t.string "reason_category", null: false
    t.text "reason_details"
    t.string "background_check_provider"
    t.datetime "pre_adverse_sent_at"
    t.text "pre_adverse_content"
    t.string "pre_adverse_delivery_method"
    t.integer "waiting_period_days", default: 5, null: false
    t.datetime "waiting_period_ends_at"
    t.boolean "candidate_disputed", default: false, null: false
    t.text "dispute_details"
    t.datetime "dispute_received_at"
    t.datetime "final_adverse_sent_at"
    t.text "final_adverse_content"
    t.string "final_adverse_delivery_method"
    t.json "attached_documents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "status"], name: "index_adverse_actions_on_application_id_and_status"
    t.index ["application_id"], name: "index_adverse_actions_on_application_id"
    t.index ["initiated_by_id"], name: "index_adverse_actions_on_initiated_by_id"
    t.index ["organization_id", "status"], name: "index_adverse_actions_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_adverse_actions_on_organization_id"
    t.index ["waiting_period_ends_at"], name: "index_adverse_actions_on_waiting_period_ends_at"
  end

  create_table "agencies", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.string "contact_email"
    t.string "contact_name"
    t.decimal "fee_percentage", precision: 5, scale: 2
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "active"], name: "index_agencies_on_organization_id_and_active"
    t.index ["organization_id", "name"], name: "index_agencies_on_organization_id_and_name"
    t.index ["organization_id"], name: "index_agencies_on_organization_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.string "key_prefix", null: false
    t.string "key_digest", null: false
    t.json "scopes", default: [], null: false
    t.datetime "last_used_at"
    t.datetime "expires_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.integer "rate_limit_per_minute", default: 60
    t.integer "rate_limit_per_hour", default: 1000
    t.integer "rate_limit_per_day", default: 10000
    t.integer "requests_today", default: 0, null: false
    t.integer "requests_this_hour", default: 0, null: false
    t.integer "requests_this_minute", default: 0, null: false
    t.integer "total_requests", default: 0, null: false
    t.datetime "minute_reset_at"
    t.datetime "hour_reset_at"
    t.datetime "day_reset_at"
    t.string "api_version", default: "v1"
    t.text "description"
    t.json "allowed_ips"
    t.index ["key_digest"], name: "index_api_keys_on_key_digest", unique: true
    t.index ["key_prefix"], name: "index_api_keys_on_key_prefix"
    t.index ["organization_id", "revoked_at"], name: "index_api_keys_on_organization_id_and_revoked_at"
    t.index ["organization_id"], name: "index_api_keys_on_organization_id"
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "application_custom_field_values", force: :cascade do |t|
    t.integer "application_id", null: false
    t.integer "custom_field_id", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "custom_field_id"], name: "idx_application_cfv_unique", unique: true
    t.index ["application_id"], name: "index_application_custom_field_values_on_application_id"
    t.index ["custom_field_id"], name: "index_application_custom_field_values_on_custom_field_id"
  end

  create_table "application_question_responses", force: :cascade do |t|
    t.integer "application_id", null: false
    t.integer "application_question_id", null: false
    t.text "text_value"
    t.boolean "boolean_value"
    t.integer "number_value"
    t.date "date_value"
    t.json "array_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "application_question_id"], name: "idx_app_question_responses_unique", unique: true
    t.index ["application_id"], name: "index_application_question_responses_on_application_id"
    t.index ["application_question_id"], name: "idx_on_application_question_id_4c224aaa2b"
  end

  create_table "application_questions", force: :cascade do |t|
    t.integer "job_id", null: false
    t.string "question", null: false
    t.text "description"
    t.string "question_type", null: false
    t.json "options"
    t.boolean "required", default: false, null: false
    t.integer "min_length"
    t.integer "max_length"
    t.integer "min_value"
    t.integer "max_value"
    t.integer "position", default: 0, null: false
    t.string "placeholder"
    t.text "help_text"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "active"], name: "index_application_questions_on_job_id_and_active"
    t.index ["job_id", "position"], name: "index_application_questions_on_job_id_and_position"
    t.index ["job_id"], name: "index_application_questions_on_job_id"
  end

  create_table "applications", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "job_id", null: false
    t.integer "candidate_id", null: false
    t.integer "current_stage_id", null: false
    t.string "status", default: "active", null: false
    t.integer "rejection_reason_id"
    t.text "rejection_notes"
    t.string "source_type", null: false
    t.string "source_detail"
    t.datetime "applied_at", null: false
    t.datetime "hired_at"
    t.datetime "rejected_at"
    t.datetime "withdrawn_at"
    t.integer "rating"
    t.boolean "starred", default: false, null: false
    t.datetime "last_activity_at", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tracking_token"
    t.boolean "i9_required", default: true
    t.string "i9_status", default: "not_started"
    t.date "expected_start_date"
    t.index ["candidate_id"], name: "index_applications_on_candidate_id"
    t.index ["current_stage_id"], name: "index_applications_on_current_stage_id"
    t.index ["discarded_at"], name: "index_applications_on_discarded_at"
    t.index ["job_id", "candidate_id"], name: "index_applications_on_job_id_and_candidate_id", unique: true
    t.index ["job_id", "current_stage_id"], name: "index_applications_on_job_id_and_current_stage_id"
    t.index ["job_id", "status"], name: "index_applications_on_job_id_and_status"
    t.index ["job_id"], name: "index_applications_on_job_id"
    t.index ["organization_id", "i9_status"], name: "index_applications_on_organization_id_and_i9_status"
    t.index ["organization_id", "last_activity_at"], name: "index_applications_on_organization_id_and_last_activity_at"
    t.index ["organization_id", "starred"], name: "index_applications_on_organization_id_and_starred", where: "starred = true"
    t.index ["organization_id", "status"], name: "index_applications_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_applications_on_organization_id"
    t.index ["rejection_reason_id"], name: "index_applications_on_rejection_reason_id"
    t.index ["tracking_token"], name: "index_applications_on_tracking_token", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "user_id"
    t.string "action", null: false
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.json "metadata", default: {}, null: false
    t.json "recorded_changes", default: {}
    t.string "ip_address"
    t.string "user_agent"
    t.string "request_id"
    t.datetime "created_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["organization_id", "action"], name: "index_audit_logs_on_organization_id_and_action"
    t.index ["organization_id", "created_at"], name: "index_audit_logs_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_audit_logs_on_organization_id"
    t.index ["request_id"], name: "index_audit_logs_on_request_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "automation_logs", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "automation_rule_id", null: false
    t.integer "application_id"
    t.integer "candidate_id"
    t.string "status", null: false
    t.string "trigger_event", null: false
    t.json "conditions_evaluated"
    t.json "actions_taken"
    t.text "error_message"
    t.datetime "triggered_at", null: false
    t.integer "execution_time_ms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "created_at"], name: "index_automation_logs_on_application_id_and_created_at"
    t.index ["application_id"], name: "index_automation_logs_on_application_id"
    t.index ["automation_rule_id", "status"], name: "index_automation_logs_on_automation_rule_id_and_status"
    t.index ["automation_rule_id"], name: "index_automation_logs_on_automation_rule_id"
    t.index ["candidate_id"], name: "index_automation_logs_on_candidate_id"
    t.index ["organization_id", "created_at"], name: "index_automation_logs_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_automation_logs_on_organization_id"
  end

  create_table "automation_rules", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "created_by_id", null: false
    t.integer "job_id"
    t.string "name", null: false
    t.text "description"
    t.string "rule_type", null: false
    t.string "trigger_event", null: false
    t.json "conditions"
    t.json "actions"
    t.boolean "active", default: true, null: false
    t.integer "priority", default: 0, null: false
    t.integer "times_triggered", default: 0, null: false
    t.datetime "last_triggered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_automation_rules_on_created_by_id"
    t.index ["job_id", "active"], name: "index_automation_rules_on_job_id_and_active"
    t.index ["job_id"], name: "index_automation_rules_on_job_id"
    t.index ["organization_id", "active"], name: "index_automation_rules_on_organization_id_and_active"
    t.index ["organization_id", "rule_type"], name: "index_automation_rules_on_organization_id_and_rule_type"
    t.index ["organization_id"], name: "index_automation_rules_on_organization_id"
    t.index ["trigger_event"], name: "index_automation_rules_on_trigger_event"
  end

  create_table "background_checks", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "application_id", null: false
    t.integer "candidate_id", null: false
    t.integer "integration_id", null: false
    t.integer "requested_by_id", null: false
    t.string "external_id"
    t.string "external_url"
    t.string "package"
    t.json "check_types"
    t.string "status", default: "pending", null: false
    t.string "result"
    t.json "result_details"
    t.text "result_summary"
    t.datetime "consent_requested_at"
    t.datetime "consent_given_at"
    t.string "consent_method"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "expires_at"
    t.integer "estimated_days"
    t.integer "adverse_action_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["adverse_action_id"], name: "index_background_checks_on_adverse_action_id"
    t.index ["application_id"], name: "index_background_checks_on_application_id", unique: true
    t.index ["candidate_id", "created_at"], name: "index_background_checks_on_candidate_id_and_created_at"
    t.index ["candidate_id"], name: "index_background_checks_on_candidate_id"
    t.index ["external_id"], name: "index_background_checks_on_external_id"
    t.index ["integration_id"], name: "index_background_checks_on_integration_id"
    t.index ["organization_id", "status"], name: "index_background_checks_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_background_checks_on_organization_id"
    t.index ["requested_by_id"], name: "index_background_checks_on_requested_by_id"
  end

  create_table "calendar_integrations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "provider", null: false
    t.string "calendar_id"
    t.text "access_token_encrypted"
    t.text "refresh_token_encrypted"
    t.datetime "token_expires_at"
    t.boolean "active", default: true, null: false
    t.datetime "last_synced_at"
    t.string "sync_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "active"], name: "index_calendar_integrations_on_user_id_and_active"
    t.index ["user_id", "provider"], name: "index_calendar_integrations_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_calendar_integrations_on_user_id"
  end

  create_table "candidate_accounts", force: :cascade do |t|
    t.integer "candidate_id", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.boolean "email_notifications", default: true, null: false
    t.boolean "job_alerts", default: false, null: false
    t.json "job_alert_criteria"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id"], name: "index_candidate_accounts_on_candidate_id", unique: true
    t.index ["confirmation_token"], name: "index_candidate_accounts_on_confirmation_token", unique: true
    t.index ["email"], name: "index_candidate_accounts_on_email", unique: true
    t.index ["reset_password_token"], name: "index_candidate_accounts_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_candidate_accounts_on_unlock_token", unique: true
  end

  create_table "candidate_custom_field_values", force: :cascade do |t|
    t.integer "candidate_id", null: false
    t.integer "custom_field_id", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id", "custom_field_id"], name: "idx_candidate_cfv_unique", unique: true
    t.index ["candidate_id"], name: "index_candidate_custom_field_values_on_candidate_id"
    t.index ["custom_field_id"], name: "index_candidate_custom_field_values_on_custom_field_id"
  end

  create_table "candidate_documents", force: :cascade do |t|
    t.integer "candidate_id", null: false
    t.integer "application_id"
    t.string "name", null: false
    t.string "document_type", null: false
    t.text "description"
    t.string "original_filename"
    t.string "content_type"
    t.integer "file_size"
    t.boolean "visible_to_employer", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_candidate_documents_on_application_id"
    t.index ["candidate_id", "document_type"], name: "index_candidate_documents_on_candidate_id_and_document_type"
    t.index ["candidate_id"], name: "index_candidate_documents_on_candidate_id"
  end

  create_table "candidate_notes", force: :cascade do |t|
    t.integer "candidate_id", null: false
    t.integer "user_id", null: false
    t.text "content", null: false
    t.string "visibility", default: "team", null: false
    t.boolean "pinned", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id", "pinned"], name: "index_candidate_notes_on_candidate_id_and_pinned"
    t.index ["candidate_id", "visibility"], name: "index_candidate_notes_on_candidate_id_and_visibility"
    t.index ["candidate_id"], name: "index_candidate_notes_on_candidate_id"
    t.index ["user_id"], name: "index_candidate_notes_on_user_id"
  end

  create_table "candidate_scores", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "application_id", null: false
    t.integer "job_id", null: false
    t.integer "candidate_id", null: false
    t.decimal "overall_score", precision: 5, scale: 2, null: false
    t.json "component_scores"
    t.json "score_explanation"
    t.string "scoring_version"
    t.datetime "scored_at", null: false
    t.boolean "manual_override", default: false, null: false
    t.integer "overridden_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_candidate_scores_on_application_id", unique: true
    t.index ["candidate_id"], name: "index_candidate_scores_on_candidate_id"
    t.index ["job_id", "overall_score"], name: "index_candidate_scores_on_job_id_and_overall_score"
    t.index ["job_id"], name: "index_candidate_scores_on_job_id"
    t.index ["organization_id", "overall_score"], name: "index_candidate_scores_on_organization_id_and_overall_score"
    t.index ["organization_id"], name: "index_candidate_scores_on_organization_id"
    t.index ["overridden_by_id"], name: "index_candidate_scores_on_overridden_by_id"
  end

  create_table "candidate_skills", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "candidate_id", null: false
    t.integer "parsed_resume_id"
    t.string "name", null: false
    t.string "normalized_name"
    t.string "category"
    t.string "proficiency_level"
    t.integer "years_experience"
    t.string "source", default: "parsed", null: false
    t.boolean "verified", default: false, null: false
    t.integer "verified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id", "name"], name: "index_candidate_skills_on_candidate_id_and_name", unique: true
    t.index ["candidate_id"], name: "index_candidate_skills_on_candidate_id"
    t.index ["category"], name: "index_candidate_skills_on_category"
    t.index ["organization_id", "normalized_name"], name: "index_candidate_skills_on_organization_id_and_normalized_name"
    t.index ["organization_id"], name: "index_candidate_skills_on_organization_id"
    t.index ["parsed_resume_id"], name: "index_candidate_skills_on_parsed_resume_id"
    t.index ["verified_by_id"], name: "index_candidate_skills_on_verified_by_id"
  end

  create_table "candidate_sources", force: :cascade do |t|
    t.integer "candidate_id", null: false
    t.string "source_type", null: false
    t.string "source_detail"
    t.integer "source_job_id"
    t.datetime "created_at", null: false
    t.index ["candidate_id", "source_type"], name: "index_candidate_sources_on_candidate_id_and_source_type"
    t.index ["candidate_id"], name: "index_candidate_sources_on_candidate_id"
    t.index ["source_job_id"], name: "index_candidate_sources_on_source_job_id"
  end

  create_table "candidate_tags", force: :cascade do |t|
    t.integer "candidate_id", null: false
    t.integer "tag_id", null: false
    t.integer "added_by_id"
    t.datetime "created_at", null: false
    t.index ["added_by_id"], name: "index_candidate_tags_on_added_by_id"
    t.index ["candidate_id", "tag_id"], name: "index_candidate_tags_on_candidate_id_and_tag_id", unique: true
    t.index ["candidate_id"], name: "index_candidate_tags_on_candidate_id"
    t.index ["tag_id"], name: "index_candidate_tags_on_tag_id"
  end

  create_table "candidates", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "location"
    t.string "linkedin_url"
    t.string "portfolio_url"
    t.text "summary"
    t.integer "referred_by_id"
    t.integer "agency_id"
    t.integer "merged_into_id"
    t.datetime "merged_at"
    t.json "parsed_profile", default: {}
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_email"
    t.string "encrypted_email_iv"
    t.string "encrypted_phone"
    t.string "encrypted_phone_iv"
    t.string "encrypted_ssn"
    t.string "encrypted_ssn_iv"
    t.string "current_company"
    t.string "current_title"
    t.text "cover_letter"
    t.string "source"
    t.text "search_text"
    t.text "skills_list"
    t.integer "years_experience"
    t.string "highest_education"
    t.string "last_job_title"
    t.string "last_company"
    t.index ["agency_id"], name: "index_candidates_on_agency_id"
    t.index ["discarded_at"], name: "index_candidates_on_discarded_at"
    t.index ["email"], name: "index_candidates_on_email"
    t.index ["merged_into_id"], name: "index_candidates_on_merged_into_id"
    t.index ["organization_id", "email"], name: "index_candidates_on_organization_id_and_email", unique: true
    t.index ["organization_id", "last_name", "first_name"], name: "idx_on_organization_id_last_name_first_name_9f1d37241f"
    t.index ["organization_id"], name: "index_candidates_on_organization_id"
    t.index ["referred_by_id"], name: "index_candidates_on_referred_by_id"
    t.index ["search_text"], name: "index_candidates_on_search_text"
  end

  create_table "competencies", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.string "description"
    t.string "category"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "active"], name: "index_competencies_on_organization_id_and_active"
    t.index ["organization_id", "category"], name: "index_competencies_on_organization_id_and_category"
    t.index ["organization_id"], name: "index_competencies_on_organization_id"
  end

  create_table "custom_fields", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "entity_type", null: false
    t.string "field_key", null: false
    t.string "label", null: false
    t.string "field_type", null: false
    t.json "options"
    t.boolean "required", default: false, null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "entity_type", "active"], name: "idx_on_organization_id_entity_type_active_28e9dd66c0"
    t.index ["organization_id", "entity_type", "field_key"], name: "idx_custom_fields_unique_key", unique: true
    t.index ["organization_id"], name: "index_custom_fields_on_organization_id"
  end

  create_table "data_retention_policies", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "data_category", null: false
    t.integer "retention_days", null: false
    t.string "retention_trigger", null: false
    t.string "action_type", default: "anonymize", null: false
    t.boolean "notify_candidate", default: true, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "active"], name: "index_data_retention_policies_on_organization_id_and_active"
    t.index ["organization_id", "data_category"], name: "idx_on_organization_id_data_category_0353d8b866"
    t.index ["organization_id"], name: "index_data_retention_policies_on_organization_id"
  end

  create_table "deletion_requests", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "candidate_id", null: false
    t.integer "processed_by_id"
    t.string "status", default: "pending", null: false
    t.string "request_source", null: false
    t.boolean "identity_verified", default: false, null: false
    t.string "verification_method"
    t.text "rejection_reason"
    t.json "data_deleted"
    t.json "data_retained"
    t.datetime "requested_at", null: false
    t.datetime "verified_at"
    t.datetime "processed_at"
    t.datetime "completed_at"
    t.boolean "legal_hold", default: false, null: false
    t.text "legal_hold_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id", "status"], name: "index_deletion_requests_on_candidate_id_and_status"
    t.index ["candidate_id"], name: "index_deletion_requests_on_candidate_id"
    t.index ["organization_id", "status"], name: "index_deletion_requests_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_deletion_requests_on_organization_id"
    t.index ["processed_by_id"], name: "index_deletion_requests_on_processed_by_id"
    t.index ["requested_at"], name: "index_deletion_requests_on_requested_at"
  end

  create_table "departments", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "parent_id"
    t.string "name", null: false
    t.string "code"
    t.integer "position", default: 0, null: false
    t.integer "default_hiring_manager_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["default_hiring_manager_id"], name: "index_departments_on_default_hiring_manager_id"
    t.index ["organization_id", "code"], name: "index_departments_on_organization_id_and_code", unique: true, where: "code IS NOT NULL"
    t.index ["organization_id", "name"], name: "index_departments_on_organization_id_and_name"
    t.index ["organization_id"], name: "index_departments_on_organization_id"
    t.index ["parent_id"], name: "index_departments_on_parent_id"
  end

  create_table "e_verify_cases", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "i9_verification_id", null: false
    t.string "case_number"
    t.string "status", default: "pending", null: false
    t.datetime "submitted_at"
    t.datetime "response_received_at"
    t.string "response_code"
    t.text "response_message"
    t.boolean "tnc_contested", default: false
    t.date "tnc_referral_date"
    t.date "tnc_response_deadline"
    t.integer "submitted_by_id"
    t.json "api_responses", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_number"], name: "index_e_verify_cases_on_case_number", unique: true
    t.index ["i9_verification_id"], name: "index_e_verify_cases_on_i9_verification_id"
    t.index ["organization_id", "status"], name: "index_e_verify_cases_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_e_verify_cases_on_organization_id"
    t.index ["submitted_by_id"], name: "index_e_verify_cases_on_submitted_by_id"
  end

  create_table "eeoc_responses", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "application_id", null: false
    t.string "gender"
    t.string "race_ethnicity"
    t.string "veteran_status"
    t.string "disability_status"
    t.boolean "consent_given", default: false, null: false
    t.datetime "consent_timestamp"
    t.string "consent_ip_address"
    t.string "collection_context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_eeoc_responses_on_application_id", unique: true
    t.index ["organization_id", "created_at"], name: "index_eeoc_responses_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_eeoc_responses_on_organization_id"
  end

  create_table "gdpr_consents", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "candidate_id", null: false
    t.string "consent_type", null: false
    t.boolean "granted", default: false, null: false
    t.text "consent_text"
    t.string "consent_version"
    t.string "collection_method"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "granted_at"
    t.datetime "withdrawn_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id", "consent_type"], name: "index_gdpr_consents_on_candidate_id_and_consent_type"
    t.index ["candidate_id"], name: "index_gdpr_consents_on_candidate_id"
    t.index ["organization_id", "consent_type"], name: "index_gdpr_consents_on_organization_id_and_consent_type"
    t.index ["organization_id", "granted"], name: "index_gdpr_consents_on_organization_id_and_granted"
    t.index ["organization_id"], name: "index_gdpr_consents_on_organization_id"
  end

  create_table "hiring_decisions", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "application_id", null: false
    t.integer "decided_by_id", null: false
    t.integer "approved_by_id"
    t.string "decision", null: false
    t.string "status", default: "pending", null: false
    t.text "rationale", null: false
    t.decimal "proposed_salary", precision: 12, scale: 2
    t.string "proposed_salary_currency", default: "USD"
    t.date "proposed_start_date"
    t.datetime "decided_at", null: false
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_hiring_decisions_on_application_id"
    t.index ["approved_by_id"], name: "index_hiring_decisions_on_approved_by_id"
    t.index ["decided_by_id"], name: "index_hiring_decisions_on_decided_by_id"
    t.index ["organization_id", "application_id"], name: "index_hiring_decisions_on_organization_id_and_application_id"
    t.index ["organization_id", "decision"], name: "index_hiring_decisions_on_organization_id_and_decision"
    t.index ["organization_id", "status"], name: "index_hiring_decisions_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_hiring_decisions_on_organization_id"
  end

  create_table "hris_exports", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "integration_id", null: false
    t.integer "application_id", null: false
    t.integer "candidate_id", null: false
    t.integer "exported_by_id", null: false
    t.string "external_id"
    t.string "external_url"
    t.string "status", default: "pending", null: false
    t.json "export_data"
    t.json "field_mapping"
    t.json "response_data"
    t.text "error_message"
    t.datetime "exported_at"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "integration_id"], name: "index_hris_exports_on_application_id_and_integration_id", unique: true
    t.index ["application_id"], name: "index_hris_exports_on_application_id"
    t.index ["candidate_id"], name: "index_hris_exports_on_candidate_id"
    t.index ["exported_by_id"], name: "index_hris_exports_on_exported_by_id"
    t.index ["external_id"], name: "index_hris_exports_on_external_id"
    t.index ["integration_id"], name: "index_hris_exports_on_integration_id"
    t.index ["organization_id", "status"], name: "index_hris_exports_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_hris_exports_on_organization_id"
  end

  create_table "i9_documents", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "i9_verification_id", null: false
    t.string "list_type", null: false
    t.string "document_type", null: false
    t.string "document_title"
    t.string "issuing_authority"
    t.string "document_number"
    t.date "expiration_date"
    t.boolean "verified", default: false
    t.integer "verified_by_id"
    t.datetime "verified_at"
    t.text "verification_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["i9_verification_id", "list_type"], name: "index_i9_documents_on_i9_verification_id_and_list_type"
    t.index ["i9_verification_id"], name: "index_i9_documents_on_i9_verification_id"
    t.index ["organization_id"], name: "index_i9_documents_on_organization_id"
    t.index ["verified_by_id"], name: "index_i9_documents_on_verified_by_id"
  end

  create_table "i9_verifications", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "application_id", null: false
    t.integer "candidate_id", null: false
    t.string "status", default: "pending_section1", null: false
    t.datetime "section1_completed_at"
    t.string "section1_signature_ip"
    t.string "section1_signature_user_agent"
    t.boolean "attestation_accepted", default: false
    t.string "citizenship_status"
    t.string "alien_number"
    t.date "alien_expiration_date"
    t.string "i94_number"
    t.string "foreign_passport_number"
    t.string "foreign_passport_country"
    t.datetime "section2_completed_at"
    t.integer "section2_completed_by_id"
    t.string "section2_signature_ip"
    t.date "employee_start_date"
    t.string "employer_title"
    t.string "employer_organization_name"
    t.string "employer_organization_address"
    t.datetime "section3_completed_at"
    t.integer "section3_completed_by_id"
    t.date "rehire_date"
    t.integer "authorized_representative_id"
    t.boolean "remote_verification", default: false
    t.date "deadline_section1"
    t.date "deadline_section2"
    t.boolean "late_completion", default: false
    t.text "late_completion_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_i9_verifications_on_application_id", unique: true
    t.index ["authorized_representative_id"], name: "index_i9_verifications_on_authorized_representative_id"
    t.index ["candidate_id"], name: "index_i9_verifications_on_candidate_id"
    t.index ["organization_id", "deadline_section2"], name: "idx_on_organization_id_deadline_section2_b611fa9d98"
    t.index ["organization_id", "status"], name: "index_i9_verifications_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_i9_verifications_on_organization_id"
    t.index ["section2_completed_by_id"], name: "index_i9_verifications_on_section2_completed_by_id"
    t.index ["section3_completed_by_id"], name: "index_i9_verifications_on_section3_completed_by_id"
  end

  create_table "integration_logs", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "integration_id", null: false
    t.string "action", null: false
    t.string "status", null: false
    t.string "direction", null: false
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "external_id"
    t.json "request_data"
    t.json "response_data"
    t.text "error_message"
    t.integer "records_processed", default: 0
    t.integer "records_created", default: 0
    t.integer "records_updated", default: 0
    t.integer "records_failed", default: 0
    t.integer "duration_ms"
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_id", "created_at"], name: "index_integration_logs_on_integration_id_and_created_at"
    t.index ["integration_id"], name: "index_integration_logs_on_integration_id"
    t.index ["organization_id", "action"], name: "index_integration_logs_on_organization_id_and_action"
    t.index ["organization_id"], name: "index_integration_logs_on_organization_id"
    t.index ["resource_type", "resource_id"], name: "index_integration_logs_on_resource_type_and_resource_id"
  end

  create_table "integrations", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "created_by_id", null: false
    t.string "integration_type", null: false
    t.string "provider", null: false
    t.string "name", null: false
    t.text "description"
    t.json "settings"
    t.string "api_key_encrypted"
    t.string "api_secret_encrypted"
    t.string "webhook_secret_encrypted"
    t.string "access_token_encrypted"
    t.string "refresh_token_encrypted"
    t.datetime "token_expires_at"
    t.string "status", default: "pending", null: false
    t.text "last_error"
    t.datetime "last_sync_at"
    t.datetime "last_error_at"
    t.boolean "auto_sync", default: true, null: false
    t.string "sync_frequency", default: "hourly"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_integrations_on_created_by_id"
    t.index ["discarded_at"], name: "index_integrations_on_discarded_at"
    t.index ["organization_id", "integration_type"], name: "index_integrations_on_organization_id_and_integration_type"
    t.index ["organization_id", "provider"], name: "index_integrations_on_organization_id_and_provider"
    t.index ["organization_id", "status"], name: "index_integrations_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_integrations_on_organization_id"
  end

  create_table "interview_kit_questions", force: :cascade do |t|
    t.integer "interview_kit_id", null: false
    t.integer "question_bank_id"
    t.text "question"
    t.text "guidance"
    t.integer "position", default: 0, null: false
    t.integer "time_allocation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interview_kit_id", "position"], name: "index_interview_kit_questions_on_interview_kit_id_and_position"
    t.index ["interview_kit_id"], name: "index_interview_kit_questions_on_interview_kit_id"
    t.index ["question_bank_id"], name: "index_interview_kit_questions_on_question_bank_id"
  end

  create_table "interview_kits", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "job_id"
    t.integer "stage_id"
    t.string "name", null: false
    t.text "description"
    t.string "interview_type"
    t.text "introduction_notes"
    t.text "closing_notes"
    t.boolean "active", default: true, null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_interview_kits_on_job_id"
    t.index ["organization_id", "active"], name: "index_interview_kits_on_organization_id_and_active"
    t.index ["organization_id", "interview_type"], name: "index_interview_kits_on_organization_id_and_interview_type"
    t.index ["organization_id", "job_id"], name: "index_interview_kits_on_organization_id_and_job_id"
    t.index ["organization_id", "name"], name: "index_interview_kits_on_organization_id_and_name"
    t.index ["organization_id"], name: "index_interview_kits_on_organization_id"
    t.index ["stage_id"], name: "index_interview_kits_on_stage_id"
  end

  create_table "interview_participants", force: :cascade do |t|
    t.integer "interview_id", null: false
    t.integer "user_id", null: false
    t.string "role", default: "interviewer", null: false
    t.string "status", default: "pending", null: false
    t.datetime "responded_at"
    t.boolean "feedback_submitted", default: false, null: false
    t.datetime "feedback_submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interview_id", "role"], name: "index_interview_participants_on_interview_id_and_role"
    t.index ["interview_id", "user_id"], name: "index_interview_participants_on_interview_id_and_user_id", unique: true
    t.index ["interview_id"], name: "index_interview_participants_on_interview_id"
    t.index ["user_id", "feedback_submitted"], name: "index_interview_participants_on_user_id_and_feedback_submitted"
    t.index ["user_id", "status"], name: "index_interview_participants_on_user_id_and_status"
    t.index ["user_id"], name: "index_interview_participants_on_user_id"
  end

  create_table "interview_self_schedules", force: :cascade do |t|
    t.integer "interview_id", null: false
    t.datetime "scheduling_starts_at", null: false
    t.datetime "scheduling_ends_at", null: false
    t.json "available_slots"
    t.integer "slot_duration_minutes", default: 60, null: false
    t.integer "buffer_minutes", default: 15, null: false
    t.integer "max_slots_per_day", default: 3
    t.string "timezone", default: "UTC", null: false
    t.text "instructions"
    t.string "status", default: "pending", null: false
    t.datetime "selected_slot"
    t.datetime "scheduled_at"
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interview_id", "status"], name: "index_interview_self_schedules_on_interview_id_and_status"
    t.index ["interview_id"], name: "index_interview_self_schedules_on_interview_id"
    t.index ["token"], name: "index_interview_self_schedules_on_token", unique: true
  end

  create_table "interviews", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "application_id", null: false
    t.integer "job_id", null: false
    t.integer "scheduled_by_id", null: false
    t.string "interview_type", null: false
    t.string "status", default: "scheduled", null: false
    t.string "title", null: false
    t.datetime "scheduled_at", null: false
    t.integer "duration_minutes", default: 60, null: false
    t.string "timezone", default: "UTC", null: false
    t.string "location"
    t.string "video_meeting_url"
    t.text "instructions"
    t.datetime "confirmed_at"
    t.datetime "completed_at"
    t.datetime "cancelled_at"
    t.string "cancellation_reason"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "status"], name: "index_interviews_on_application_id_and_status"
    t.index ["application_id"], name: "index_interviews_on_application_id"
    t.index ["discarded_at"], name: "index_interviews_on_discarded_at"
    t.index ["job_id", "scheduled_at"], name: "index_interviews_on_job_id_and_scheduled_at"
    t.index ["job_id"], name: "index_interviews_on_job_id"
    t.index ["organization_id", "scheduled_at"], name: "index_interviews_on_organization_id_and_scheduled_at"
    t.index ["organization_id", "status"], name: "index_interviews_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_interviews_on_organization_id"
    t.index ["scheduled_by_id"], name: "index_interviews_on_scheduled_by_id"
  end

  create_table "job_approvals", force: :cascade do |t|
    t.integer "job_id", null: false
    t.integer "approver_id", null: false
    t.string "status", default: "pending", null: false
    t.text "notes"
    t.integer "sequence", default: 0, null: false
    t.datetime "decided_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id", "status"], name: "index_job_approvals_on_approver_id_and_status"
    t.index ["approver_id"], name: "index_job_approvals_on_approver_id"
    t.index ["job_id", "sequence"], name: "index_job_approvals_on_job_id_and_sequence"
    t.index ["job_id", "status"], name: "index_job_approvals_on_job_id_and_status"
    t.index ["job_id"], name: "index_job_approvals_on_job_id"
  end

  create_table "job_board_postings", force: :cascade do |t|
    t.integer "job_id", null: false
    t.string "board_name", null: false
    t.string "external_id"
    t.string "external_url"
    t.string "status", default: "pending", null: false
    t.datetime "posted_at"
    t.datetime "expires_at"
    t.datetime "removed_at"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id"
    t.integer "integration_id"
    t.integer "posted_by_id"
    t.datetime "last_synced_at"
    t.text "last_error"
    t.integer "views_count", default: 0
    t.integer "clicks_count", default: 0
    t.integer "applications_count", default: 0
    t.index ["external_id"], name: "index_job_board_postings_on_external_id"
    t.index ["integration_id"], name: "index_job_board_postings_on_integration_id"
    t.index ["job_id", "board_name"], name: "index_job_board_postings_on_job_id_and_board_name"
    t.index ["job_id", "status"], name: "index_job_board_postings_on_job_id_and_status"
    t.index ["job_id"], name: "index_job_board_postings_on_job_id"
    t.index ["organization_id", "status"], name: "index_job_board_postings_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_job_board_postings_on_organization_id"
    t.index ["posted_by_id"], name: "index_job_board_postings_on_posted_by_id"
  end

  create_table "job_custom_field_values", force: :cascade do |t|
    t.integer "job_id", null: false
    t.integer "custom_field_id", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_field_id"], name: "index_job_custom_field_values_on_custom_field_id"
    t.index ["job_id", "custom_field_id"], name: "index_job_custom_field_values_on_job_id_and_custom_field_id", unique: true
    t.index ["job_id"], name: "index_job_custom_field_values_on_job_id"
  end

  create_table "job_requirements", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "job_id", null: false
    t.string "requirement_type", null: false
    t.string "name", null: false
    t.string "normalized_name"
    t.string "importance", default: "required", null: false
    t.integer "weight", default: 1, null: false
    t.integer "min_years"
    t.integer "max_years"
    t.string "education_level"
    t.string "field_of_study"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "position"], name: "index_job_requirements_on_job_id_and_position"
    t.index ["job_id", "requirement_type"], name: "index_job_requirements_on_job_id_and_requirement_type"
    t.index ["job_id"], name: "index_job_requirements_on_job_id"
    t.index ["organization_id", "normalized_name"], name: "index_job_requirements_on_organization_id_and_normalized_name"
    t.index ["organization_id"], name: "index_job_requirements_on_organization_id"
  end

  create_table "job_stages", force: :cascade do |t|
    t.integer "job_id", null: false
    t.integer "stage_id", null: false
    t.integer "position", null: false
    t.boolean "required_interview", default: false, null: false
    t.bigint "scorecard_template_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "position"], name: "index_job_stages_on_job_id_and_position", unique: true
    t.index ["job_id", "stage_id"], name: "index_job_stages_on_job_id_and_stage_id", unique: true
    t.index ["job_id"], name: "index_job_stages_on_job_id"
    t.index ["stage_id"], name: "index_job_stages_on_stage_id"
  end

  create_table "job_templates", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "department_id"
    t.string "name", null: false
    t.string "title", null: false
    t.text "description"
    t.text "requirements"
    t.string "location_type", default: "onsite", null: false
    t.string "employment_type", default: "full_time", null: false
    t.integer "salary_min"
    t.integer "salary_max"
    t.string "salary_currency", default: "USD"
    t.integer "default_headcount", default: 1, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_job_templates_on_department_id"
    t.index ["organization_id", "active"], name: "index_job_templates_on_organization_id_and_active"
    t.index ["organization_id", "name"], name: "index_job_templates_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_job_templates_on_organization_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "department_id"
    t.integer "hiring_manager_id"
    t.integer "recruiter_id"
    t.string "title", null: false
    t.text "description"
    t.text "requirements"
    t.text "internal_notes"
    t.string "location"
    t.string "location_type", default: "onsite", null: false
    t.string "employment_type", default: "full_time", null: false
    t.integer "salary_min"
    t.integer "salary_max"
    t.string "salary_currency", default: "USD"
    t.boolean "salary_visible", default: false, null: false
    t.string "status", default: "draft", null: false
    t.datetime "opened_at"
    t.datetime "closed_at"
    t.string "close_reason"
    t.integer "headcount", default: 1, null: false
    t.integer "filled_count", default: 0, null: false
    t.string "remote_id"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_jobs_on_department_id"
    t.index ["discarded_at"], name: "index_jobs_on_discarded_at"
    t.index ["hiring_manager_id"], name: "index_jobs_on_hiring_manager_id"
    t.index ["organization_id", "department_id"], name: "index_jobs_on_organization_id_and_department_id"
    t.index ["organization_id", "remote_id"], name: "index_jobs_on_organization_id_and_remote_id", unique: true, where: "remote_id IS NOT NULL"
    t.index ["organization_id", "status"], name: "index_jobs_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_jobs_on_organization_id"
    t.index ["recruiter_id"], name: "index_jobs_on_recruiter_id"
  end

  create_table "lookup_types", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "code", null: false
    t.string "name", null: false
    t.string "description"
    t.boolean "system_managed", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "active"], name: "index_lookup_types_on_organization_id_and_active"
    t.index ["organization_id", "code"], name: "index_lookup_types_on_organization_id_and_code", unique: true
    t.index ["organization_id"], name: "index_lookup_types_on_organization_id"
  end

  create_table "lookup_values", force: :cascade do |t|
    t.integer "lookup_type_id", null: false
    t.string "code", null: false
    t.json "translations", default: {}, null: false
    t.json "metadata", default: {}
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lookup_type_id", "active", "position"], name: "index_lookup_values_on_lookup_type_id_and_active_and_position"
    t.index ["lookup_type_id", "code"], name: "index_lookup_values_on_lookup_type_id_and_code", unique: true
    t.index ["lookup_type_id"], name: "index_lookup_values_on_lookup_type_id"
  end

  create_table "offer_approvals", force: :cascade do |t|
    t.integer "offer_id", null: false
    t.integer "approver_id", null: false
    t.integer "sequence", default: 1, null: false
    t.string "status", default: "pending", null: false
    t.text "comments"
    t.datetime "requested_at"
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id", "status"], name: "index_offer_approvals_on_approver_id_and_status"
    t.index ["approver_id"], name: "index_offer_approvals_on_approver_id"
    t.index ["offer_id", "sequence"], name: "index_offer_approvals_on_offer_id_and_sequence"
    t.index ["offer_id"], name: "index_offer_approvals_on_offer_id"
  end

  create_table "offer_templates", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "template_type", default: "standard", null: false
    t.text "subject_line"
    t.text "body", null: false
    t.text "footer"
    t.json "available_variables"
    t.boolean "active", default: true, null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "active"], name: "index_offer_templates_on_organization_id_and_active"
    t.index ["organization_id", "is_default"], name: "index_offer_templates_on_organization_id_and_is_default"
    t.index ["organization_id", "template_type"], name: "index_offer_templates_on_organization_id_and_template_type"
    t.index ["organization_id"], name: "index_offer_templates_on_organization_id"
  end

  create_table "offers", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "application_id", null: false
    t.integer "offer_template_id"
    t.integer "created_by_id", null: false
    t.string "title", null: false
    t.string "status", default: "draft", null: false
    t.decimal "salary", precision: 12, scale: 2
    t.string "salary_period", default: "yearly"
    t.string "currency", default: "USD"
    t.decimal "signing_bonus", precision: 12, scale: 2
    t.decimal "annual_bonus_target", precision: 5, scale: 2
    t.string "equity_type"
    t.integer "equity_shares"
    t.string "equity_vesting_schedule"
    t.string "employment_type"
    t.date "proposed_start_date"
    t.string "work_location"
    t.string "reports_to"
    t.string "department"
    t.text "custom_terms"
    t.text "rendered_content"
    t.datetime "expires_at"
    t.datetime "sent_at"
    t.datetime "responded_at"
    t.string "response"
    t.text "decline_reason"
    t.string "signature_request_id"
    t.string "signature_status"
    t.datetime "signed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "status"], name: "index_offers_on_application_id_and_status"
    t.index ["application_id"], name: "index_offers_on_application_id"
    t.index ["created_by_id"], name: "index_offers_on_created_by_id"
    t.index ["offer_template_id"], name: "index_offers_on_offer_template_id"
    t.index ["organization_id", "status"], name: "index_offers_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_offers_on_organization_id"
    t.index ["signature_request_id"], name: "index_offers_on_signature_request_id"
  end

  create_table "organization_brandings", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "primary_color", default: "#0d6efd"
    t.string "secondary_color", default: "#6c757d"
    t.string "accent_color", default: "#0dcaf0"
    t.string "text_color", default: "#212529"
    t.string "background_color", default: "#ffffff"
    t.string "font_family", default: "system-ui, -apple-system, sans-serif"
    t.string "heading_font_family"
    t.text "custom_css"
    t.string "company_tagline"
    t.text "about_company"
    t.text "benefits_summary"
    t.text "culture_description"
    t.string "linkedin_url"
    t.string "twitter_url"
    t.string "facebook_url"
    t.string "instagram_url"
    t.string "glassdoor_url"
    t.string "meta_title"
    t.text "meta_description"
    t.string "meta_keywords"
    t.boolean "show_salary_ranges", default: false, null: false
    t.boolean "show_department_filter", default: true, null: false
    t.boolean "show_location_filter", default: true, null: false
    t.boolean "show_employment_type_filter", default: true, null: false
    t.boolean "enable_job_alerts", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_fonts_url"
    t.text "email_footer_text"
    t.string "custom_from_address"
    t.string "custom_email_domain"
    t.boolean "email_domain_verified", default: false, null: false
    t.string "report_footer_text"
    t.boolean "show_powered_by", default: true, null: false
    t.string "support_email"
    t.index ["organization_id"], name: "index_organization_brandings_on_organization_id", unique: true
  end

  create_table "organization_settings", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "key", null: false
    t.json "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "key"], name: "index_organization_settings_on_organization_id_and_key", unique: true
    t.index ["organization_id"], name: "index_organization_settings_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "subdomain", null: false
    t.string "domain"
    t.string "logo_url"
    t.string "timezone", default: "UTC", null: false
    t.string "default_currency", default: "USD", null: false
    t.string "default_locale", default: "en", null: false
    t.json "settings", default: {}, null: false
    t.string "billing_email"
    t.string "plan", default: "trial", null: false
    t.datetime "trial_ends_at"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_organizations_on_discarded_at"
    t.index ["domain"], name: "index_organizations_on_domain", unique: true, where: "domain IS NOT NULL"
    t.index ["subdomain"], name: "index_organizations_on_subdomain", unique: true
  end

  create_table "parsed_resumes", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "candidate_id", null: false
    t.integer "resume_id"
    t.string "parser_provider"
    t.string "parser_version"
    t.string "status", default: "pending", null: false
    t.text "error_message"
    t.string "parsed_name"
    t.string "parsed_email"
    t.string "parsed_phone"
    t.string "parsed_location"
    t.string "parsed_linkedin_url"
    t.text "summary"
    t.text "objective"
    t.json "work_experience"
    t.json "education"
    t.json "skills"
    t.json "certifications"
    t.json "languages"
    t.json "raw_response"
    t.integer "years_of_experience"
    t.string "highest_education_level"
    t.date "most_recent_job_end"
    t.boolean "reviewed", default: false, null: false
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id", "created_at"], name: "index_parsed_resumes_on_candidate_id_and_created_at"
    t.index ["candidate_id"], name: "index_parsed_resumes_on_candidate_id"
    t.index ["organization_id", "status"], name: "index_parsed_resumes_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_parsed_resumes_on_organization_id"
    t.index ["resume_id"], name: "index_parsed_resumes_on_resume_id"
    t.index ["reviewed_by_id"], name: "index_parsed_resumes_on_reviewed_by_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "resource", null: false
    t.string "action", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.index ["resource", "action"], name: "index_permissions_on_resource_and_action", unique: true
  end

  create_table "question_banks", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "competency_id"
    t.text "question", null: false
    t.text "guidance"
    t.string "question_type", null: false
    t.string "difficulty"
    t.string "tags"
    t.integer "usage_count", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competency_id"], name: "index_question_banks_on_competency_id"
    t.index ["organization_id", "active"], name: "index_question_banks_on_organization_id_and_active"
    t.index ["organization_id", "competency_id"], name: "index_question_banks_on_organization_id_and_competency_id"
    t.index ["organization_id", "question_type"], name: "index_question_banks_on_organization_id_and_question_type"
    t.index ["organization_id"], name: "index_question_banks_on_organization_id"
  end

  create_table "rejection_reasons", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.string "category", null: false
    t.boolean "requires_notes", default: false, null: false
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "active"], name: "index_rejection_reasons_on_organization_id_and_active"
    t.index ["organization_id", "category"], name: "index_rejection_reasons_on_organization_id_and_category"
    t.index ["organization_id"], name: "index_rejection_reasons_on_organization_id"
  end

  create_table "report_snapshots", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "report_type", null: false
    t.string "period_type", null: false
    t.date "period_start", null: false
    t.date "period_end", null: false
    t.json "data", default: {}, null: false
    t.json "metadata", default: {}
    t.datetime "generated_at", null: false
    t.integer "generated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["generated_by_id"], name: "index_report_snapshots_on_generated_by_id"
    t.index ["organization_id", "report_type", "period_start"], name: "idx_report_snapshots_org_type_period"
    t.index ["organization_id", "report_type", "period_type"], name: "idx_report_snapshots_org_type_period_type"
    t.index ["organization_id"], name: "index_report_snapshots_on_organization_id"
  end

  create_table "resumes", force: :cascade do |t|
    t.integer "candidate_id", null: false
    t.string "filename", null: false
    t.string "content_type", null: false
    t.integer "file_size", null: false
    t.string "storage_key", null: false
    t.text "raw_text"
    t.json "parsed_data", default: {}
    t.boolean "primary", default: false, null: false
    t.datetime "parsed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id", "primary"], name: "index_resumes_on_candidate_id_and_primary", where: "\"primary\" = true"
    t.index ["candidate_id"], name: "index_resumes_on_candidate_id"
    t.index ["storage_key"], name: "index_resumes_on_storage_key", unique: true
  end

  create_table "role_permissions", force: :cascade do |t|
    t.integer "role_id", null: false
    t.integer "permission_id", null: false
    t.json "conditions"
    t.datetime "created_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.string "description"
    t.boolean "system_role", default: false, null: false
    t.json "permissions", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_roles_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_roles_on_organization_id"
  end

  create_table "saved_searches", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.json "criteria", null: false
    t.string "search_type", default: "candidate", null: false
    t.boolean "alert_enabled", default: false, null: false
    t.string "alert_frequency"
    t.datetime "last_alert_at"
    t.integer "last_result_count"
    t.integer "run_count", default: 0, null: false
    t.datetime "last_run_at"
    t.boolean "shared", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alert_enabled"], name: "index_saved_searches_on_alert_enabled"
    t.index ["organization_id", "shared"], name: "index_saved_searches_on_organization_id_and_shared"
    t.index ["organization_id", "user_id"], name: "index_saved_searches_on_organization_id_and_user_id"
    t.index ["organization_id"], name: "index_saved_searches_on_organization_id"
    t.index ["user_id"], name: "index_saved_searches_on_user_id"
  end

  create_table "scorecard_responses", force: :cascade do |t|
    t.integer "scorecard_id", null: false
    t.integer "scorecard_template_item_id", null: false
    t.integer "rating"
    t.boolean "yes_no_value"
    t.text "text_value"
    t.string "select_value"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scorecard_id", "scorecard_template_item_id"], name: "idx_scorecard_responses_unique", unique: true
    t.index ["scorecard_id"], name: "index_scorecard_responses_on_scorecard_id"
    t.index ["scorecard_template_item_id"], name: "index_scorecard_responses_on_scorecard_template_item_id"
  end

  create_table "scorecard_template_items", force: :cascade do |t|
    t.integer "scorecard_template_section_id", null: false
    t.string "name", null: false
    t.string "item_type", default: "rating", null: false
    t.text "guidance"
    t.integer "rating_scale", default: 5
    t.json "options", default: []
    t.integer "position", default: 0, null: false
    t.boolean "required", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scorecard_template_section_id", "position"], name: "idx_template_items_on_section_and_position"
    t.index ["scorecard_template_section_id"], name: "idx_on_scorecard_template_section_id_0ac8688741"
  end

  create_table "scorecard_template_sections", force: :cascade do |t|
    t.integer "scorecard_template_id", null: false
    t.string "name", null: false
    t.string "section_type", default: "competencies", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.integer "weight", default: 100
    t.boolean "required", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scorecard_template_id", "position"], name: "idx_on_scorecard_template_id_position_fa1eaa6c34"
    t.index ["scorecard_template_id"], name: "index_scorecard_template_sections_on_scorecard_template_id"
  end

  create_table "scorecard_templates", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "job_id"
    t.integer "stage_id"
    t.string "name", null: false
    t.string "interview_type"
    t.text "description"
    t.boolean "active", default: true, null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "stage_id"], name: "index_scorecard_templates_on_job_id_and_stage_id"
    t.index ["job_id"], name: "index_scorecard_templates_on_job_id"
    t.index ["organization_id", "active"], name: "index_scorecard_templates_on_organization_id_and_active"
    t.index ["organization_id", "is_default"], name: "index_scorecard_templates_on_organization_id_and_is_default"
    t.index ["organization_id"], name: "index_scorecard_templates_on_organization_id"
    t.index ["stage_id"], name: "index_scorecard_templates_on_stage_id"
  end

  create_table "scorecards", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "interview_id", null: false
    t.integer "interview_participant_id", null: false
    t.integer "scorecard_template_id"
    t.string "status", default: "draft", null: false
    t.string "overall_recommendation"
    t.text "summary"
    t.text "strengths"
    t.text "concerns"
    t.decimal "overall_score", precision: 5, scale: 2
    t.datetime "submitted_at"
    t.datetime "locked_at"
    t.boolean "visible_to_team", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interview_id", "status"], name: "index_scorecards_on_interview_id_and_status"
    t.index ["interview_id"], name: "index_scorecards_on_interview_id"
    t.index ["interview_participant_id"], name: "index_scorecards_on_interview_participant_id"
    t.index ["organization_id", "status"], name: "index_scorecards_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_scorecards_on_organization_id"
    t.index ["scorecard_template_id"], name: "index_scorecards_on_scorecard_template_id"
  end

  create_table "sso_configs", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "provider", null: false
    t.string "issuer_url"
    t.string "client_id"
    t.string "client_secret"
    t.json "metadata", default: {}
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "saml_entity_id"
    t.string "saml_sso_url"
    t.string "saml_slo_url"
    t.text "saml_certificate"
    t.string "saml_fingerprint"
    t.string "saml_fingerprint_algorithm", default: "sha256"
    t.string "oidc_discovery_url"
    t.string "oidc_authorization_endpoint"
    t.string "oidc_token_endpoint"
    t.string "oidc_userinfo_endpoint"
    t.string "oidc_jwks_uri"
    t.string "oidc_scopes", default: "openid profile email"
    t.json "attribute_mapping"
    t.boolean "auto_provision_users", default: false, null: false
    t.integer "default_role_id"
    t.json "allowed_domains"
    t.boolean "enforce_sso", default: false, null: false
    t.boolean "debug_mode", default: false, null: false
    t.datetime "last_login_at"
    t.integer "login_count", default: 0, null: false
    t.index ["organization_id", "provider"], name: "index_sso_configs_on_organization_id_and_provider", unique: true
    t.index ["organization_id"], name: "index_sso_configs_on_organization_id"
  end

  create_table "sso_identities", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "sso_config_id", null: false
    t.string "provider_uid", null: false
    t.json "provider_data", default: {}
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.index ["sso_config_id", "provider_uid"], name: "index_sso_identities_on_sso_config_id_and_provider_uid", unique: true
    t.index ["sso_config_id"], name: "index_sso_identities_on_sso_config_id"
    t.index ["user_id"], name: "index_sso_identities_on_user_id"
  end

  create_table "stage_transitions", force: :cascade do |t|
    t.integer "application_id", null: false
    t.integer "from_stage_id"
    t.integer "to_stage_id", null: false
    t.integer "moved_by_id"
    t.text "notes"
    t.integer "duration_hours"
    t.datetime "created_at", null: false
    t.index ["application_id", "created_at"], name: "index_stage_transitions_on_application_id_and_created_at"
    t.index ["application_id"], name: "index_stage_transitions_on_application_id"
    t.index ["from_stage_id"], name: "index_stage_transitions_on_from_stage_id"
    t.index ["moved_by_id"], name: "index_stage_transitions_on_moved_by_id"
    t.index ["to_stage_id"], name: "index_stage_transitions_on_to_stage_id"
  end

  create_table "stages", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.string "stage_type", null: false
    t.integer "position", null: false
    t.boolean "is_terminal", default: false, null: false
    t.boolean "is_default", default: false, null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "is_default"], name: "index_stages_on_organization_id_and_is_default", where: "is_default = true"
    t.index ["organization_id", "position"], name: "index_stages_on_organization_id_and_position"
    t.index ["organization_id", "stage_type"], name: "index_stages_on_organization_id_and_stage_type"
    t.index ["organization_id"], name: "index_stages_on_organization_id"
  end

  create_table "tags", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.index ["organization_id", "name"], name: "index_tags_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_tags_on_organization_id"
  end

  create_table "talent_pool_members", force: :cascade do |t|
    t.integer "talent_pool_id", null: false
    t.integer "candidate_id", null: false
    t.integer "added_by_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.string "source", default: "manual", null: false
    t.datetime "updated_at"
    t.index ["added_by_id"], name: "index_talent_pool_members_on_added_by_id"
    t.index ["candidate_id"], name: "index_talent_pool_members_on_candidate_id"
    t.index ["talent_pool_id", "candidate_id"], name: "index_talent_pool_members_on_talent_pool_id_and_candidate_id", unique: true
    t.index ["talent_pool_id"], name: "index_talent_pool_members_on_talent_pool_id"
  end

  create_table "talent_pools", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "owner_id", null: false
    t.boolean "shared", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pool_type", default: "manual", null: false
    t.integer "saved_search_id"
    t.boolean "active", default: true, null: false
    t.string "color"
    t.integer "candidates_count", default: 0, null: false
    t.index ["organization_id", "active"], name: "index_talent_pools_on_organization_id_and_active"
    t.index ["organization_id", "name"], name: "index_talent_pools_on_organization_id_and_name"
    t.index ["organization_id", "pool_type"], name: "index_talent_pools_on_organization_id_and_pool_type"
    t.index ["organization_id"], name: "index_talent_pools_on_organization_id"
    t.index ["owner_id"], name: "index_talent_pools_on_owner_id"
    t.index ["saved_search_id"], name: "index_talent_pools_on_saved_search_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.datetime "granted_at", null: false
    t.integer "granted_by_id"
    t.datetime "created_at", null: false
    t.index ["granted_by_id"], name: "index_user_roles_on_granted_by_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token_digest", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "expires_at", null: false
    t.datetime "last_active_at"
    t.datetime "created_at", null: false
    t.index ["expires_at"], name: "index_user_sessions_on_expires_at"
    t.index ["token_digest"], name: "index_user_sessions_on_token_digest", unique: true
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "email", null: false
    t.string "encrypted_password"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "avatar_url"
    t.boolean "active", default: true, null: false
    t.datetime "confirmed_at"
    t.datetime "locked_at"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "password_changed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.datetime "remember_created_at"
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email"
    t.index ["organization_id", "email"], name: "index_users_on_organization_id_and_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true, where: "unlock_token IS NOT NULL"
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "webhook_id", null: false
    t.string "event_type", null: false
    t.string "event_id", null: false
    t.json "payload", null: false
    t.string "status", default: "pending", null: false
    t.integer "attempt_count", default: 0, null: false
    t.integer "max_attempts", default: 5, null: false
    t.integer "response_status"
    t.text "response_body"
    t.integer "response_time_ms"
    t.text "error_message"
    t.string "error_type"
    t.datetime "scheduled_at"
    t.datetime "delivered_at"
    t.datetime "next_retry_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_webhook_deliveries_on_event_id", unique: true
    t.index ["organization_id", "event_type"], name: "index_webhook_deliveries_on_organization_id_and_event_type"
    t.index ["organization_id"], name: "index_webhook_deliveries_on_organization_id"
    t.index ["status", "next_retry_at"], name: "index_webhook_deliveries_on_status_and_next_retry_at"
    t.index ["webhook_id", "status"], name: "index_webhook_deliveries_on_webhook_id_and_status"
    t.index ["webhook_id"], name: "index_webhook_deliveries_on_webhook_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "created_by_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "url", null: false
    t.string "secret_encrypted"
    t.json "events", null: false
    t.string "http_method", default: "POST", null: false
    t.json "headers"
    t.boolean "active", default: true, null: false
    t.string "status", default: "active", null: false
    t.integer "success_count", default: 0, null: false
    t.integer "failure_count", default: 0, null: false
    t.integer "consecutive_failures", default: 0, null: false
    t.datetime "last_triggered_at"
    t.datetime "last_success_at"
    t.datetime "last_failure_at"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_webhooks_on_created_by_id"
    t.index ["discarded_at"], name: "index_webhooks_on_discarded_at"
    t.index ["organization_id", "active"], name: "index_webhooks_on_organization_id_and_active"
    t.index ["organization_id"], name: "index_webhooks_on_organization_id"
    t.index ["status"], name: "index_webhooks_on_status"
  end

  create_table "work_authorizations", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "candidate_id", null: false
    t.integer "i9_verification_id"
    t.string "authorization_type", null: false
    t.date "valid_from"
    t.date "valid_until"
    t.boolean "indefinite", default: false
    t.string "document_number"
    t.string "issuing_authority"
    t.boolean "reverification_required", default: false
    t.date "reverification_due_date"
    t.boolean "reverification_reminder_sent", default: false
    t.datetime "reverification_reminder_sent_at"
    t.integer "created_by_id"
    t.integer "verified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id", "valid_until"], name: "index_work_authorizations_on_candidate_id_and_valid_until"
    t.index ["candidate_id"], name: "index_work_authorizations_on_candidate_id"
    t.index ["created_by_id"], name: "index_work_authorizations_on_created_by_id"
    t.index ["i9_verification_id"], name: "index_work_authorizations_on_i9_verification_id"
    t.index ["organization_id", "valid_until"], name: "index_work_authorizations_on_organization_id_and_valid_until"
    t.index ["organization_id"], name: "index_work_authorizations_on_organization_id"
    t.index ["verified_by_id"], name: "index_work_authorizations_on_verified_by_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "adverse_actions", "applications"
  add_foreign_key "adverse_actions", "organizations"
  add_foreign_key "adverse_actions", "users", column: "initiated_by_id"
  add_foreign_key "agencies", "organizations"
  add_foreign_key "api_keys", "organizations"
  add_foreign_key "api_keys", "users"
  add_foreign_key "application_custom_field_values", "applications"
  add_foreign_key "application_custom_field_values", "custom_fields"
  add_foreign_key "application_question_responses", "application_questions"
  add_foreign_key "application_question_responses", "applications"
  add_foreign_key "application_questions", "jobs"
  add_foreign_key "applications", "candidates"
  add_foreign_key "applications", "jobs"
  add_foreign_key "applications", "organizations"
  add_foreign_key "applications", "rejection_reasons"
  add_foreign_key "applications", "stages", column: "current_stage_id"
  add_foreign_key "audit_logs", "organizations"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "automation_logs", "applications"
  add_foreign_key "automation_logs", "automation_rules"
  add_foreign_key "automation_logs", "candidates"
  add_foreign_key "automation_logs", "organizations"
  add_foreign_key "automation_rules", "jobs"
  add_foreign_key "automation_rules", "organizations"
  add_foreign_key "automation_rules", "users", column: "created_by_id"
  add_foreign_key "background_checks", "adverse_actions"
  add_foreign_key "background_checks", "applications"
  add_foreign_key "background_checks", "candidates"
  add_foreign_key "background_checks", "integrations"
  add_foreign_key "background_checks", "organizations"
  add_foreign_key "background_checks", "users", column: "requested_by_id"
  add_foreign_key "calendar_integrations", "users"
  add_foreign_key "candidate_accounts", "candidates"
  add_foreign_key "candidate_custom_field_values", "candidates"
  add_foreign_key "candidate_custom_field_values", "custom_fields"
  add_foreign_key "candidate_documents", "applications"
  add_foreign_key "candidate_documents", "candidates"
  add_foreign_key "candidate_notes", "candidates"
  add_foreign_key "candidate_notes", "users"
  add_foreign_key "candidate_scores", "applications"
  add_foreign_key "candidate_scores", "candidates"
  add_foreign_key "candidate_scores", "jobs"
  add_foreign_key "candidate_scores", "organizations"
  add_foreign_key "candidate_scores", "users", column: "overridden_by_id"
  add_foreign_key "candidate_skills", "candidates"
  add_foreign_key "candidate_skills", "organizations"
  add_foreign_key "candidate_skills", "parsed_resumes"
  add_foreign_key "candidate_skills", "users", column: "verified_by_id"
  add_foreign_key "candidate_sources", "candidates"
  add_foreign_key "candidate_sources", "jobs", column: "source_job_id"
  add_foreign_key "candidate_tags", "candidates"
  add_foreign_key "candidate_tags", "tags"
  add_foreign_key "candidate_tags", "users", column: "added_by_id"
  add_foreign_key "candidates", "agencies"
  add_foreign_key "candidates", "candidates", column: "merged_into_id"
  add_foreign_key "candidates", "organizations"
  add_foreign_key "candidates", "users", column: "referred_by_id"
  add_foreign_key "competencies", "organizations"
  add_foreign_key "custom_fields", "organizations"
  add_foreign_key "data_retention_policies", "organizations"
  add_foreign_key "deletion_requests", "candidates"
  add_foreign_key "deletion_requests", "organizations"
  add_foreign_key "deletion_requests", "users", column: "processed_by_id"
  add_foreign_key "departments", "departments", column: "parent_id"
  add_foreign_key "departments", "organizations"
  add_foreign_key "departments", "users", column: "default_hiring_manager_id"
  add_foreign_key "e_verify_cases", "i9_verifications"
  add_foreign_key "e_verify_cases", "organizations"
  add_foreign_key "e_verify_cases", "users", column: "submitted_by_id"
  add_foreign_key "eeoc_responses", "applications"
  add_foreign_key "eeoc_responses", "organizations"
  add_foreign_key "gdpr_consents", "candidates"
  add_foreign_key "gdpr_consents", "organizations"
  add_foreign_key "hiring_decisions", "applications"
  add_foreign_key "hiring_decisions", "organizations"
  add_foreign_key "hiring_decisions", "users", column: "approved_by_id"
  add_foreign_key "hiring_decisions", "users", column: "decided_by_id"
  add_foreign_key "hris_exports", "applications"
  add_foreign_key "hris_exports", "candidates"
  add_foreign_key "hris_exports", "integrations"
  add_foreign_key "hris_exports", "organizations"
  add_foreign_key "hris_exports", "users", column: "exported_by_id"
  add_foreign_key "i9_documents", "i9_verifications"
  add_foreign_key "i9_documents", "organizations"
  add_foreign_key "i9_documents", "users", column: "verified_by_id"
  add_foreign_key "i9_verifications", "applications"
  add_foreign_key "i9_verifications", "candidates"
  add_foreign_key "i9_verifications", "organizations"
  add_foreign_key "i9_verifications", "users", column: "authorized_representative_id"
  add_foreign_key "i9_verifications", "users", column: "section2_completed_by_id"
  add_foreign_key "i9_verifications", "users", column: "section3_completed_by_id"
  add_foreign_key "integration_logs", "integrations"
  add_foreign_key "integration_logs", "organizations"
  add_foreign_key "integrations", "organizations"
  add_foreign_key "integrations", "users", column: "created_by_id"
  add_foreign_key "interview_kit_questions", "interview_kits"
  add_foreign_key "interview_kit_questions", "question_banks"
  add_foreign_key "interview_kits", "jobs"
  add_foreign_key "interview_kits", "organizations"
  add_foreign_key "interview_kits", "stages"
  add_foreign_key "interview_participants", "interviews"
  add_foreign_key "interview_participants", "users"
  add_foreign_key "interview_self_schedules", "interviews"
  add_foreign_key "interviews", "applications"
  add_foreign_key "interviews", "jobs"
  add_foreign_key "interviews", "organizations"
  add_foreign_key "interviews", "users", column: "scheduled_by_id"
  add_foreign_key "job_approvals", "jobs"
  add_foreign_key "job_approvals", "users", column: "approver_id"
  add_foreign_key "job_board_postings", "integrations"
  add_foreign_key "job_board_postings", "jobs"
  add_foreign_key "job_board_postings", "organizations"
  add_foreign_key "job_board_postings", "users", column: "posted_by_id"
  add_foreign_key "job_custom_field_values", "custom_fields"
  add_foreign_key "job_custom_field_values", "jobs"
  add_foreign_key "job_requirements", "jobs"
  add_foreign_key "job_requirements", "organizations"
  add_foreign_key "job_stages", "jobs"
  add_foreign_key "job_stages", "stages"
  add_foreign_key "job_templates", "departments"
  add_foreign_key "job_templates", "organizations"
  add_foreign_key "jobs", "departments"
  add_foreign_key "jobs", "organizations"
  add_foreign_key "jobs", "users", column: "hiring_manager_id"
  add_foreign_key "jobs", "users", column: "recruiter_id"
  add_foreign_key "lookup_types", "organizations"
  add_foreign_key "lookup_values", "lookup_types"
  add_foreign_key "offer_approvals", "offers"
  add_foreign_key "offer_approvals", "users", column: "approver_id"
  add_foreign_key "offer_templates", "organizations"
  add_foreign_key "offers", "applications"
  add_foreign_key "offers", "offer_templates"
  add_foreign_key "offers", "organizations"
  add_foreign_key "offers", "users", column: "created_by_id"
  add_foreign_key "organization_brandings", "organizations"
  add_foreign_key "organization_settings", "organizations"
  add_foreign_key "parsed_resumes", "candidates"
  add_foreign_key "parsed_resumes", "organizations"
  add_foreign_key "parsed_resumes", "resumes"
  add_foreign_key "parsed_resumes", "users", column: "reviewed_by_id"
  add_foreign_key "question_banks", "competencies"
  add_foreign_key "question_banks", "organizations"
  add_foreign_key "rejection_reasons", "organizations"
  add_foreign_key "report_snapshots", "organizations"
  add_foreign_key "report_snapshots", "users", column: "generated_by_id"
  add_foreign_key "resumes", "candidates"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "roles", "organizations"
  add_foreign_key "saved_searches", "organizations"
  add_foreign_key "saved_searches", "users"
  add_foreign_key "scorecard_responses", "scorecard_template_items"
  add_foreign_key "scorecard_responses", "scorecards"
  add_foreign_key "scorecard_template_items", "scorecard_template_sections"
  add_foreign_key "scorecard_template_sections", "scorecard_templates"
  add_foreign_key "scorecard_templates", "jobs"
  add_foreign_key "scorecard_templates", "organizations"
  add_foreign_key "scorecard_templates", "stages"
  add_foreign_key "scorecards", "interview_participants"
  add_foreign_key "scorecards", "interviews"
  add_foreign_key "scorecards", "organizations"
  add_foreign_key "scorecards", "scorecard_templates"
  add_foreign_key "sso_configs", "organizations"
  add_foreign_key "sso_identities", "sso_configs"
  add_foreign_key "sso_identities", "users"
  add_foreign_key "stage_transitions", "applications"
  add_foreign_key "stage_transitions", "stages", column: "from_stage_id"
  add_foreign_key "stage_transitions", "stages", column: "to_stage_id"
  add_foreign_key "stage_transitions", "users", column: "moved_by_id"
  add_foreign_key "stages", "organizations"
  add_foreign_key "tags", "organizations"
  add_foreign_key "talent_pool_members", "candidates"
  add_foreign_key "talent_pool_members", "talent_pools"
  add_foreign_key "talent_pool_members", "users", column: "added_by_id"
  add_foreign_key "talent_pools", "organizations"
  add_foreign_key "talent_pools", "saved_searches"
  add_foreign_key "talent_pools", "users", column: "owner_id"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "user_roles", "users", column: "granted_by_id"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "users", "organizations"
  add_foreign_key "webhook_deliveries", "organizations"
  add_foreign_key "webhook_deliveries", "webhooks"
  add_foreign_key "webhooks", "organizations"
  add_foreign_key "webhooks", "users", column: "created_by_id"
  add_foreign_key "work_authorizations", "candidates"
  add_foreign_key "work_authorizations", "i9_verifications"
  add_foreign_key "work_authorizations", "organizations"
  add_foreign_key "work_authorizations", "users", column: "created_by_id"
  add_foreign_key "work_authorizations", "users", column: "verified_by_id"
end
