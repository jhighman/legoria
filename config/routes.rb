Rails.application.routes.draw do
  # Authentication
  devise_for :users

  # Jobs
  resources :jobs do
    member do
      post :submit_for_approval
      post :approve
      post :reject
      post :put_on_hold
      post :close
      post :reopen
      post :duplicate
    end

    collection do
      get :pending_approval
    end

    # Pipeline (Kanban board)
    resource :pipeline, only: [:show], controller: "pipeline" do
      get :list
      member do
        post "applications/:id/move_stage", action: :move_stage, as: :move_stage
        post "applications/:id/reject", action: :reject, as: :reject_application
        post "applications/:id/star", action: :star, as: :star_application
        post "applications/:id/unstar", action: :unstar, as: :unstar_application
        post "applications/:id/rate", action: :rate, as: :rate_application
      end
    end

    # Custom application questions (Phase 3)
    resources :application_questions do
      member do
        post :move_up
        post :move_down
        post :toggle_active
      end
    end
  end

  # Job templates
  resources :job_templates

  # Candidates
  resources :candidates do
    member do
      post :merge
      post :add_note
      post :upload_resume
    end

    # Candidate documents (Phase 3)
    resources :candidate_documents, only: [:index, :show, :destroy] do
      member do
        post :toggle_visibility
      end
    end

    # GDPR consents (Phase 4)
    resources :gdpr_consents, only: [:index, :show, :new, :create] do
      member do
        post :withdraw
      end
    end

    # Deletion requests (Phase 4)
    resources :deletion_requests, only: [:new, :create]
  end

  # Deletion requests - standalone routes (Phase 4)
  resources :deletion_requests, only: [:index, :show] do
    member do
      post :verify
      post :process_request
      post :reject
      post :place_hold
      post :remove_hold
    end
  end

  # Applications (nested under jobs for context)
  resources :jobs do
    resources :applications, only: [:new, :create, :show] do
      member do
        post :move_stage
        post :reject
        post :withdraw
        post :star
        post :unstar
        post :rate
      end
    end
  end

  # Direct application routes (for candidate-centric view)
  resources :applications, only: [:index, :show, :update] do
    member do
      post :move_stage
      post :reject
      post :withdraw
    end

    # Nested interviews for scheduling context
    resources :interviews, only: [:new, :create]

    # Hiring decisions (Sprint 9)
    resources :hiring_decisions, only: [:new, :create]

    # Offers (Phase 4)
    resources :offers, only: [:new, :create]

    # Adverse actions (Phase 4)
    resources :adverse_actions, only: [:new, :create]
  end

  # Offers (Phase 4)
  resources :offers do
    member do
      post :submit_for_approval
      post :send_offer
      post :withdraw
    end
  end

  # Offer approvals (Phase 4)
  resources :offer_approvals, only: [] do
    member do
      post :approve
      post :reject
    end
  end

  # Adverse actions (Phase 4)
  resources :adverse_actions, only: [:index, :show, :edit, :update] do
    member do
      post :send_pre_adverse
      post :record_dispute
      post :send_final
      post :cancel
    end
  end

  # Hiring decisions (standalone routes for list/show/approval)
  resources :hiring_decisions, only: [:index, :show] do
    member do
      post :approve
      post :reject_approval
    end
  end

  # Interviews (standalone routes)
  resources :interviews do
    member do
      post :confirm
      post :cancel
      post :complete
      post :mark_no_show
    end

    # Scorecard for this interview (Sprint 8)
    resource :scorecard, only: [:show, :edit, :update] do
      post :submit
    end

    # Self-scheduling (Phase 3)
    resource :self_schedule, only: [:new, :create, :show], controller: "interview_self_schedules"
  end

  # Interviewer preparation page (Sprint 9)
  get "interviewer/prep/:interview_id", to: "interviewer_prep#show", as: :interviewer_prep

  # Question bank library (Sprint 9)
  resources :question_banks do
    member do
      post :activate
      post :deactivate
    end
  end

  # Interview kits (Sprint 9)
  resources :interview_kits do
    member do
      post :duplicate
      post :activate
      post :deactivate
      post :set_default
    end
  end

  # Admin namespace
  namespace :admin do
    resources :users do
      member do
        patch :activate
        patch :deactivate
      end
    end

    resources :roles, only: [:index, :show] do
      member do
        post :assign_user
        delete :remove_user
      end
    end

    resources :lookup_types, path: "lookups", only: [:index, :show, :edit, :update] do
      resources :lookup_values, only: [:new, :create, :edit, :update, :destroy] do
        member do
          patch :move
          patch :toggle_active
        end
      end
    end

    resources :audit_logs, only: [:index, :show]

    # Scorecard templates (Sprint 8)
    resources :scorecard_templates do
      member do
        post :duplicate
      end
    end

    # Organization branding (Phase 3)
    resource :organization_branding, only: [:show, :edit, :update]

    # Offer templates (Phase 4)
    resources :offer_templates do
      member do
        post :duplicate
        post :make_default
      end
    end

    # Data retention policies (Phase 4)
    resources :data_retention_policies do
      member do
        post :toggle_active
      end
    end

    # I-9 Verifications (Phase 8)
    resources :i9_verifications do
      member do
        get :section2
        post :complete_section2
        get :section3
        post :complete_section3
      end
      collection do
        get :pending
        get :overdue
      end
    end

    # Work Authorizations (Phase 8)
    resources :work_authorizations, only: [:index, :show] do
      collection do
        get :expiring
      end
    end
  end

  # EEOC responses - public form and admin index (Phase 4)
  resources :eeoc_responses, only: [:index, :show]
  get "eeoc/:token" => "eeoc_responses#new", as: :eeoc_form
  post "eeoc/:token" => "eeoc_responses#create"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Public Career Site (no authentication required)
  get "careers" => "career_site#index", as: :careers
  get "careers/:id" => "career_site#show", as: :career
  get "careers/:id/apply" => "public_applications#new", as: :apply_career
  post "careers/:id/apply" => "public_applications#create"
  get "application/status" => "public_applications#status_lookup", as: :application_status
  get "application/status/:token" => "public_applications#status", as: :application_status_check

  # Self-scheduling for candidates (Phase 3)
  get "schedule/:token" => "self_schedule#show", as: :self_schedule
  post "schedule/:token/select" => "self_schedule#select_slot", as: :self_schedule_select
  get "schedule/:token/confirmation" => "self_schedule#confirmation", as: :self_schedule_confirmation

  # Candidate portal (Phase 3) - optional account-based access
  devise_for :candidate_accounts, path: "candidate", controllers: {
    sessions: "candidate_accounts/sessions",
    registrations: "candidate_accounts/registrations",
    passwords: "candidate_accounts/passwords"
  }

  namespace :candidate_portal, path: "portal" do
    get "/" => "candidate_portal#dashboard", as: :dashboard
    get "applications" => "candidate_portal#applications", as: :applications
    get "applications/:id" => "candidate_portal#application", as: :application
    get "documents" => "candidate_portal#documents", as: :documents
    post "documents" => "candidate_portal#upload_document", as: :upload_document
    delete "documents/:id" => "candidate_portal#delete_document", as: :delete_document
    get "profile" => "candidate_portal#profile", as: :profile
    patch "profile" => "candidate_portal#update_profile", as: :update_profile
    get "job-alerts" => "candidate_portal#job_alerts", as: :job_alerts
    patch "job-alerts" => "candidate_portal#update_job_alerts", as: :update_job_alerts

    # I-9 Section 1 (Phase 8)
    resources :i9_verifications, only: [:show], path: "i9" do
      member do
        get :section1
        post :complete_section1
      end
    end
  end

  # Reports & Analytics (Phase 7)
  namespace :reports do
    get "/" => "dashboard#index", as: :dashboard

    resources :time_to_hire, only: [:index] do
      get :export, on: :collection
    end

    resources :sources, only: [:index] do
      get :export, on: :collection
    end

    resources :pipeline, only: [:index] do
      get :export, on: :collection
    end

    resources :operational, only: [:index] do
      collection do
        get :recruiter_productivity
        get :requisition_aging
        get :export
      end
    end

    # Admin-only diversity reports
    resources :eeoc, only: [:index] do
      collection do
        get :export
        get :pdf
      end
    end

    resources :diversity, only: [:index] do
      collection do
        get :adverse_impact
        get :pdf
      end
    end

    # I-9 Compliance Reports (Phase 8)
    resources :i9_compliance, only: [:index] do
      collection do
        get :export
        get :pdf
      end
    end

    # Work Authorization Reports (Phase 8)
    resources :work_authorizations, only: [:index] do
      collection do
        get :expiring
        get :export
      end
    end
  end

  # Dashboard (root)
  root "dashboard#index"
end
