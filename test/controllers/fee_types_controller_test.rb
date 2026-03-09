# frozen_string_literal: true

require "test_helper"

class FeeTypesControllerTest < ActionDispatch::IntegrationTest
  test "index renders fee types catalog" do
    get fee_types_url

    assert_response :success
    assert_select "h1", text: /Fee Types/
    assert_select "a", text: "New Fee Type"
    assert_select "td", text: fee_types(:maintenance).code
  end

  test "new renders fee type form" do
    get new_fee_type_url

    assert_response :success
    assert_select "form"
    assert_select "input[name='fee_type[code]']"
    assert_select "input[name='fee_type[name]']"
    assert_select "input[name='fee_type[default_amount_cents]']"
    assert_select "select[name='fee_type[gl_account_id]']"
    assert_select "select[name='fee_type[status]']"
  end

  test "create creates fee type and redirects" do
    assert_difference "FeeType.count", 1 do
      post fee_types_url, params: {
        fee_type: {
          code: "WIRE_OUT",
          name: "Outgoing Wire Fee",
          default_amount_cents: 2_500,
          gl_account_id: gl_accounts(:ten).id,
          status: Bankcore::Enums::STATUS_ACTIVE
        }
      }
    end

    assert_redirected_to fee_types_path
    fee_type = FeeType.order(:id).last
    assert_equal "WIRE_OUT", fee_type.code
    assert_equal gl_accounts(:ten).id, fee_type.gl_account_id
  end

  test "edit renders existing fee type" do
    get edit_fee_type_url(fee_types(:maintenance))

    assert_response :success
    assert_select "h1", text: /Edit Fee Type/
    assert_select "input[name='fee_type[code]'][value=?]", fee_types(:maintenance).code
    assert_select "input[name='fee_type[name]'][value=?]", fee_types(:maintenance).name
  end

  test "update modifies fee type and redirects" do
    patch fee_type_url(fee_types(:service_charge)), params: {
      fee_type: {
        code: "SERVICE_CHARGE",
        name: "Updated Service Charge",
        default_amount_cents: 900,
        gl_account_id: gl_accounts(:eleven).id,
        status: Bankcore::Enums::STATUS_INACTIVE
      }
    }

    assert_redirected_to fee_types_path
    fee_type = fee_types(:service_charge).reload
    assert_equal "Updated Service Charge", fee_type.name
    assert_equal 900, fee_type.default_amount_cents
    assert_equal gl_accounts(:eleven).id, fee_type.gl_account_id
    assert_equal Bankcore::Enums::STATUS_INACTIVE, fee_type.status
  end
end
