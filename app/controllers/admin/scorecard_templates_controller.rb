# frozen_string_literal: true

module Admin
  class ScorecardTemplatesController < BaseController
    before_action :set_template, only: [:show, :edit, :update, :destroy, :duplicate]

    def index
      @templates = ScorecardTemplate.kept
                                    .includes(:job, :stage, :scorecard_template_sections)
                                    .order(created_at: :desc)

      @templates = @templates.where(active: true) if params[:active] == "true"
      @templates = @templates.where(job_id: params[:job_id]) if params[:job_id].present?
    end

    def show
      @sections = @template.scorecard_template_sections.includes(:scorecard_template_items)
    end

    def new
      @template = ScorecardTemplate.new
      @template.scorecard_template_sections.build
    end

    def create
      @template = ScorecardTemplate.new(template_params)

      if @template.save
        redirect_to admin_scorecard_template_path(@template), notice: "Scorecard template created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @sections = @template.scorecard_template_sections.includes(:scorecard_template_items)
    end

    def update
      if @template.update(template_params)
        redirect_to admin_scorecard_template_path(@template), notice: "Scorecard template updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @template.destroy
      redirect_to admin_scorecard_templates_path, notice: "Scorecard template deleted successfully."
    end

    def duplicate
      new_template = @template.duplicate
      redirect_to edit_admin_scorecard_template_path(new_template), notice: "Template duplicated. Edit the copy below."
    end

    private

    def set_template
      @template = ScorecardTemplate.find(params[:id])
    end

    def template_params
      params.require(:scorecard_template).permit(
        :name, :description, :job_id, :stage_id, :interview_type, :active, :is_default,
        scorecard_template_sections_attributes: [
          :id, :name, :section_type, :description, :position, :weight, :required, :_destroy,
          scorecard_template_items_attributes: [
            :id, :name, :item_type, :guidance, :rating_scale, :position, :required, :_destroy,
            options: []
          ]
        ]
      )
    end
  end
end
