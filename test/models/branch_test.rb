# frozen_string_literal: true

require "test_helper"

class BranchTest < ActiveSupport::TestCase
  test "validates branch_code presence" do
    branch = Branch.new(name: "Test", status: "active")
    assert_not branch.valid?
    assert_includes branch.errors[:branch_code], "can't be blank"
  end

  test "validates branch_code uniqueness" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Branch.create!(branch_code: "MAIN", name: "Duplicate", status: "active")
    end
  end

  test "validates status inclusion" do
    branch = branches(:one)
    branch.status = "invalid"
    assert_not branch.valid?
    assert_includes branch.errors[:status], "is not included in the list"
  end

  test "has many accounts" do
    branch = branches(:one)
    assert_respond_to branch, :accounts
    assert_includes branch.accounts, accounts(:one)
  end
end
