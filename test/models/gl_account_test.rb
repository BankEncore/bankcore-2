# frozen_string_literal: true

require "test_helper"

class GlAccountTest < ActiveSupport::TestCase
  test "validates gl_number presence and uniqueness" do
    gl = GlAccount.new(name: "Test", category: "asset", normal_balance: "debit", status: "active")
    assert_not gl.valid?
    assert_includes gl.errors[:gl_number], "can't be blank"

    assert_raises(ActiveRecord::RecordInvalid) do
      GlAccount.create!(gl_number: "5190", name: "Duplicate", category: "expense", normal_balance: "debit", status: "active")
    end
  end

  test "validates category inclusion" do
    gl = gl_accounts(:one)
    gl.category = "invalid"
    assert_not gl.valid?
  end

  test "validates normal_balance inclusion" do
    gl = gl_accounts(:one)
    gl.normal_balance = "invalid"
    assert_not gl.valid?
  end
end
