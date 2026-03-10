# frozen_string_literal: true

class PartyLookupsController < ApplicationController
  MAX_RESULTS = 20

  def index
    query = params[:q].to_s.strip
    parties = query.present? ? matched_parties(query) : Party.none

    render json: {
      parties: parties.map { |party| PartyContextPayloadBuilder.build(party) }
    }
  end

  private

  def matched_parties(query)
    escaped_query = ActiveRecord::Base.sanitize_sql_like(query)
    like_query = "%#{escaped_query}%"

    Party
      .includes(:primary_branch, :account_owners)
      .where(status: Bankcore::Enums::STATUS_ACTIVE)
      .where("party_number LIKE :query OR display_name LIKE :query", query: like_query)
      .order(:display_name, :party_number)
      .limit(MAX_RESULTS)
  end
end
