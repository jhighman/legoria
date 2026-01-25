# frozen_string_literal: true

class CompleteI9Section2Service < ApplicationService
  # Completes Section 2 of I-9 verification (employer portion)
  #
  # @example
  #   result = CompleteI9Section2Service.call(
  #     i9_verification: verification,
  #     section2_params: {
  #       employer_title: "HR Manager",
  #       employer_organization_name: "Acme Corp",
  #       employer_organization_address: "123 Main St, City, ST 12345"
  #     },
  #     documents: [
  #       { list_type: "list_a", document_type: "us_passport", document_number: "123456789", file: uploaded_file }
  #     ],
  #     completed_by: current_user,
  #     ip_address: request.remote_ip
  #   )

  option :i9_verification
  option :section2_params
  option :documents
  option :completed_by
  option :ip_address

  def call
    yield validate_status
    yield validate_employer_fields
    yield validate_documents
    yield verify_documents
    yield update_section2
    yield create_work_authorization
    yield transition_status

    Success(i9_verification)
  end

  private

  def validate_status
    # Must be in section1_complete or pending_section2
    unless i9_verification.status.in?(%w[section1_complete pending_section2])
      return Failure(:invalid_status)
    end

    # Transition to pending_section2 if in section1_complete
    if i9_verification.status == "section1_complete"
      i9_verification.begin_section2!
    end

    Success(true)
  rescue StateMachines::InvalidTransition => e
    Failure(e.message)
  end

  def validate_employer_fields
    unless section2_params[:employer_title].present?
      return Failure(:employer_title_required)
    end

    unless section2_params[:employer_organization_name].present?
      return Failure(:employer_organization_name_required)
    end

    unless section2_params[:employer_organization_address].present?
      return Failure(:employer_organization_address_required)
    end

    Success(true)
  end

  def validate_documents
    return Failure(:no_documents_provided) if documents.blank?

    # Must have List A OR (List B + List C)
    list_a = documents.select { |d| d[:list_type] == "list_a" }
    list_b = documents.select { |d| d[:list_type] == "list_b" }
    list_c = documents.select { |d| d[:list_type] == "list_c" }

    if list_a.any?
      Success(true)
    elsif list_b.any? && list_c.any?
      Success(true)
    else
      Failure(:invalid_document_combination)
    end
  end

  def verify_documents
    documents.each do |doc_params|
      i9_doc = i9_verification.i9_documents.build(
        organization: Current.organization,
        list_type: doc_params[:list_type],
        document_type: doc_params[:document_type],
        document_title: doc_params[:document_title],
        issuing_authority: doc_params[:issuing_authority],
        document_number: doc_params[:document_number],
        expiration_date: doc_params[:expiration_date]
      )

      unless i9_doc.save
        return Failure(i9_doc.errors.full_messages)
      end

      # Attach file if provided
      if doc_params[:file].present?
        i9_doc.file.attach(doc_params[:file])
      end

      # Verify document
      i9_doc.verify!(completed_by)
    end

    Success(true)
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages)
  end

  def update_section2
    late = Date.current > i9_verification.deadline_section2

    attrs = section2_params.slice(
      :employer_title,
      :employer_organization_name,
      :employer_organization_address
    ).merge(
      section2_completed_at: Time.current,
      section2_completed_by: completed_by,
      section2_signature_ip: ip_address,
      late_completion: late
    )

    if late && section2_params[:late_reason].present?
      attrs[:late_completion_reason] = section2_params[:late_reason]
    elsif late
      attrs[:late_completion_reason] = "Section 2 completed #{(Date.current - i9_verification.deadline_section2).to_i} days after deadline"
    end

    if i9_verification.update(attrs)
      Success(i9_verification)
    else
      Failure(i9_verification.errors.full_messages)
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages)
  end

  def create_work_authorization
    auth = WorkAuthorization.new(
      organization: Current.organization,
      candidate: i9_verification.candidate,
      i9_verification: i9_verification,
      authorization_type: map_citizenship_to_authorization_type,
      valid_from: i9_verification.employee_start_date,
      valid_until: i9_verification.alien_expiration_date,
      indefinite: indefinite_authorization?,
      created_by: completed_by,
      verified_by: completed_by
    )

    if auth.save
      Success(auth)
    else
      Failure(auth.errors.full_messages)
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages)
  end

  def transition_status
    i9_verification.complete_section2!

    # If E-Verify not required, mark as verified
    unless Current.organization.respond_to?(:e_verify_required?) && Current.organization.e_verify_required?
      i9_verification.verify!
    end

    # Send notification
    I9NotificationJob.perform_later(
      i9_verification.application_id,
      "section2_complete"
    )

    Success(i9_verification)
  rescue StateMachines::InvalidTransition => e
    Failure(e.message)
  end

  def map_citizenship_to_authorization_type
    case i9_verification.citizenship_status
    when "citizen", "noncitizen_national"
      "citizen"
    when "permanent_resident"
      "permanent_resident"
    when "alien_authorized"
      "ead"
    else
      "other"
    end
  end

  def indefinite_authorization?
    %w[citizen noncitizen_national permanent_resident].include?(i9_verification.citizenship_status)
  end
end
