# frozen_string_literal: true

# Stores a provider's name and email address.
class Provider < ApplicationRecord
  has_many :provider_client_relationships, dependent: nil
  has_many :clients, through: :provider_client_relationships
end
