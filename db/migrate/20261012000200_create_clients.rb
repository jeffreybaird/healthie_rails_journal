# frozen_string_literal: true

# Creates the client records used by the data-model foundation.
class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
