# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      username: "sessuser",
      display_name: "Session User",
      status: "active",
      password: "secret",
      password_confirmation: "secret"
    )
  end

  test "new renders login form" do
    get login_url
    assert_response :success
    assert_select "form[action=?]", login_path
    assert_select "input[name=username]"
    assert_select "input[name=password]"
  end

  test "create signs in with valid credentials" do
    post login_url, params: { username: "sessuser", password: "secret" }
    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
  end

  test "create rejects invalid credentials" do
    post login_url, params: { username: "sessuser", password: "wrong" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "destroy signs out" do
    post login_url, params: { username: "sessuser", password: "secret" }
    assert session[:user_id].present?

    delete logout_url
    assert_redirected_to login_path
    assert_nil session[:user_id]
  end
end
