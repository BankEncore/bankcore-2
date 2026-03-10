class AddContextJsonToOverrideRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :override_requests, :context_json, :text
  end
end
