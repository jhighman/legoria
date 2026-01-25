# frozen_string_literal: true

module CandidatesHelper
  def timeline_item_bg_class(type)
    case type
    when "application" then "bg-primary"
    when "transition" then "bg-info"
    when "note" then "bg-warning"
    when "resume" then "bg-success"
    else "bg-secondary"
    end
  end

  def timeline_item_icon(type)
    icon_class = case type
    when "application" then "bi-briefcase"
    when "transition" then "bi-arrow-right"
    when "note" then "bi-chat-left-text"
    when "resume" then "bi-file-earmark-text"
    else "bi-clock"
    end

    content_tag(:i, nil, class: "bi #{icon_class} text-white small")
  end
end
