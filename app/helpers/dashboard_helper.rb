# frozen_string_literal: true

module DashboardHelper
  def activity_icon(action)
    category = action.split(".").first
    action_type = action.split(".").last

    case category
    when "job"
      case action_type
      when "created" then "plus-circle"
      when "updated" then "pencil"
      when "status_changed" then "arrow-right"
      when "archived" then "archive"
      else "briefcase"
      end
    when "application"
      case action_type
      when "created" then "person-plus"
      when "stage_changed" then "arrow-right"
      when "rejected" then "x-circle"
      when "hired" then "trophy"
      else "file-person"
      end
    when "candidate"
      case action_type
      when "created" then "person-plus"
      when "updated" then "pencil"
      when "merged" then "people"
      else "person"
      end
    when "user"
      case action_type
      when "created" then "person-plus"
      when "signed_in" then "box-arrow-in-right"
      when "deactivated" then "person-slash"
      else "person-gear"
      end
    else
      "circle"
    end
  end
end
