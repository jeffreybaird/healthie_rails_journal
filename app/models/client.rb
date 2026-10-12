# frozen_string_literal: true

# Stores a client's name and email address.
class Client < ApplicationRecord
  has_many :provider_client_relationships, dependent: nil
  has_many :providers, through: :provider_client_relationships
end
