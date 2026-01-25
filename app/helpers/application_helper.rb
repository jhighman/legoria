module ApplicationHelper
  include PlatformBrandHelper

  def i9_status_color(status)
    case status.to_s
    when "pending_section1"
      "warning"
    when "section1_complete"
      "info"
    when "pending_section2"
      "primary"
    when "section2_complete"
      "success"
    when "pending_everify"
      "secondary"
    when "everify_tnc"
      "warning"
    when "verified"
      "success"
    when "failed"
      "danger"
    when "expired"
      "secondary"
    else
      "secondary"
    end
  end
end
