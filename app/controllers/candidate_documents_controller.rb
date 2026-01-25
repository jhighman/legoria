# frozen_string_literal: true

class CandidateDocumentsController < ApplicationController
  before_action :set_candidate
  before_action :set_document, only: [:show, :destroy, :toggle_visibility]

  def index
    authorize CandidateDocument
    @documents = @candidate.candidate_documents
                            .with_attached_file
                            .includes(:application)
                            .order(created_at: :desc)
  end

  def show
    authorize @document

    if @document.file.attached?
      redirect_to rails_blob_path(@document.file, disposition: "attachment")
    else
      redirect_to candidate_candidate_documents_path(@candidate), alert: "File not found."
    end
  end

  def destroy
    authorize @document
    @document.destroy
    redirect_to candidate_candidate_documents_path(@candidate), notice: "Document deleted."
  end

  def toggle_visibility
    authorize @document, :update?
    @document.toggle_visibility!
    redirect_to candidate_candidate_documents_path(@candidate),
                notice: "Document visibility #{@document.visible_to_employer? ? 'enabled' : 'disabled'}."
  end

  private

  def set_candidate
    @candidate = Candidate.find(params[:candidate_id])
  end

  def set_document
    @document = @candidate.candidate_documents.find(params[:id])
  end
end
