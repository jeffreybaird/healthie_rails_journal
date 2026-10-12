# frozen_string_literal: true

# Creates the provider records used by the data-model foundation.
class CreateProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :providers do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
