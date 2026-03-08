# frozen_string_literal: true

module ApplicationHelper
  def current_business_date
    BusinessDateService.current.strftime("%Y-%m-%d")
  rescue BusinessDateService::NoOpenBusinessDateError
    "—"
  end

  def current_business_state
    BusinessDate.exists?(status: Bankcore::Enums::BUSINESS_DATE_OPEN) ? "open" : "closed"
  end

  def workspace_user_label
    return "Guest" unless current_user

    current_user.display_name.presence || current_user.username
  end

  def workspace_branch_label
    return "Unassigned Workspace" unless current_user&.primary_branch

    "#{current_user.primary_branch.branch_code} - #{current_user.primary_branch.name}"
  end

  def status_pill_class(status)
    variant = case status.to_s.downcase
    when "posted", "approved", "active", "open", "usable", "success"
      "success"
    when "pending", "draft", "validated", "warning", "review_needed", "review", "override_required"
      "warning"
    when "reversed", "denied", "closed", "inactive", "expired", "failed", "error", "rejected"
      "error"
    else
      "neutral"
    end

    "ui-status-pill ui-status-pill-#{variant}"
  end

  def leg_type_pill_class(leg_type)
    variant = leg_type.to_s == Bankcore::Enums::LEG_TYPE_DEBIT ? "error" : "success"
    "ui-status-pill ui-status-pill-#{variant}"
  end

  def app_nav_link_class(path)
    active = current_page?(path) || request.path.start_with?(path)
    active ? "app-nav-link app-nav-link-active" : "app-nav-link"
  end
end
