# frozen_string_literal: true

module ApplicationHelper
  AppNavLink = Struct.new(:label, :path, :path_prefixes, keyword_init: true)

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
    when "reversed", "denied", "closed", "inactive", "expired", "failed", "error", "rejected", "blocked"
      "error"
    else
      "neutral"
    end

    "ui-status-pill ui-status-pill-#{variant}"
  end

  def safe_return_to_for_link(return_to)
    path = return_to.to_s.strip
    return nil if path.blank?
    return nil unless path.start_with?("/") && !path.include?("//")

    path
  end

  def leg_type_pill_class(leg_type)
    variant = leg_type.to_s == Bankcore::Enums::LEG_TYPE_DEBIT ? "error" : "success"
    "ui-status-pill ui-status-pill-#{variant}"
  end

  def app_nav_link_class(path:, path_prefixes: nil)
    active = app_nav_active_for?(path: path, path_prefixes: path_prefixes)
    active ? "app-nav-link app-nav-link-active" : "app-nav-link"
  end

  def app_navigation_sections
    @app_navigation_sections ||= [
      {
        label: "Primary Workspace",
        links: [
          AppNavLink.new(label: "Transactions", path: transactions_path),
          AppNavLink.new(label: "Bank Drafts", path: bank_drafts_path),
          AppNavLink.new(label: "Business Dates", path: business_dates_path),
          AppNavLink.new(label: "Overrides", path: override_requests_path)
        ]
      },
      {
        label: "Customer Operations",
        links: [
          AppNavLink.new(label: "Accounts", path: accounts_path),
          AppNavLink.new(label: "New Account", path: new_account_path),
          AppNavLink.new(label: "Parties", path: parties_path),
          AppNavLink.new(label: "Branches", path: branches_path)
        ]
      },
      {
        label: "Back Office Review",
        links: [
          AppNavLink.new(label: "Account Products", path: account_products_path),
          AppNavLink.new(label: "Fee Types", path: fee_types_path),
          AppNavLink.new(label: "GL Accounts", path: gl_accounts_path),
          AppNavLink.new(label: "Trial Balance", path: trial_balances_path),
          AppNavLink.new(label: "Fee Assessments", path: fee_assessments_path),
          AppNavLink.new(label: "Interest Accruals", path: interest_accruals_path),
          AppNavLink.new(label: "Interest Postings", path: interest_postings_path),
          AppNavLink.new(label: "Audit Events", path: audit_events_path)
        ]
      }
    ]
  end

  def app_current_nav_section
    app_navigation_sections.find do |section|
      section[:links].any? do |link|
        app_nav_active_for?(path: link.path, path_prefixes: link.path_prefixes)
      end
    end
  end

  def app_current_nav_link
    app_current_nav_section&.fetch(:links)&.find do |link|
      app_nav_active_for?(path: link.path, path_prefixes: link.path_prefixes)
    end
  end

  def app_nav_active_for?(path:, path_prefixes: nil)
    return true if current_page?(path)

    prefixes = Array(path_prefixes.presence || path).map { |prefix| prefix.to_s.chomp("/") }
    current_path = request.path.to_s.chomp("/")
    prefixes.any? do |prefix|
      current_path == prefix || current_path.start_with?("#{prefix}/")
    end
  end
end
