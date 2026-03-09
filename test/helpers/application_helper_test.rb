# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "app_nav_link_class treats nested paths as active" do
    with_nav_context("/trial-balance/1") do
      assert_equal "app-nav-link app-nav-link-active", app_nav_link_class(path: trial_balances_path)
    end
  end

  test "current navigation resolves section and link from nested report paths" do
    with_nav_context("/trial-balance/1") do
      assert_equal "Back Office Review", app_current_nav_section[:label]
      assert_equal "Trial Balance", app_current_nav_link.label
    end
  end

  private

  def with_nav_context(current_path)
    request_stub = Struct.new(:path).new(current_path)
    singleton_class.define_method(:request) { request_stub }
    singleton_class.define_method(:current_page?) { |path| path.to_s == current_path }
    yield
  ensure
    singleton_class.send(:remove_method, :request) if singleton_class.instance_methods(false).include?(:request)
    singleton_class.send(:remove_method, :current_page?) if singleton_class.instance_methods(false).include?(:current_page?)
  end
end
