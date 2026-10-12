# frozen_string_literal: true

# Creates provider-client relationships with a plan for each unique pair.
class CreateProviderClientRelationships < ActiveRecord::Migration[8.1]
  def change
    create_table :provider_client_relationships do |t|
      t.references :provider, null: false, foreign_key: true, index: false
      t.references :client, null: false, foreign_key: true
      t.string :plan, null: false

      t.timestamps
    end

    add_index :provider_client_relationships, %i[provider_id client_id], unique: true
  end
end
