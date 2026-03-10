# frozen_string_literal: true

require "test_helper"

class PartyLookupsControllerTest < ActionDispatch::IntegrationTest
  test "index returns matching active parties" do
    get party_lookups_url, params: { q: "Test" }, as: :json

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal [ parties(:one).id ], payload.fetch("parties").map { |party| party.fetch("id") }

    party_payload = payload.fetch("parties").first
    assert_equal "P001", party_payload.fetch("party_number")
    assert_equal "Test Customer", party_payload.fetch("display_name")
    assert_equal 2, party_payload.fetch("linked_account_count")
  end

  test "index excludes inactive parties" do
    party = Party.create!(
      party_number: "P999",
      display_name: "Inactive Customer",
      party_type: "person",
      status: "inactive"
    )

    get party_lookups_url, params: { q: party.party_number }, as: :json

    assert_response :success
    payload = JSON.parse(response.body)
    assert_empty payload.fetch("parties")
  end
end
