# frozen_string_literal: true

class PartyContextPayloadBuilder
  def self.build(party)
    new(party).build
  end

  def initialize(party)
    @party = party
  end

  def build
    {
      id: @party.id,
      party_number: @party.party_number,
      display_name: @party.display_name,
      party_type: @party.party_type,
      status: @party.status,
      branch_code: @party.primary_branch&.branch_code,
      linked_account_count: @party.account_owners.size,
      display_label: display_label
    }
  end

  private

  def display_label
    [
      @party.display_name,
      @party.party_number,
      @party.party_type
    ].compact.join(" — ")
  end
end
