# frozen_string_literal: true

# Stores a client's plan with one provider.
class ProviderClientRelationship < ApplicationRecord
  belongs_to :provider
  belongs_to :client

  validates :client_id, uniqueness: { scope: :provider_id }
  validates :plan, inclusion: { in: %w[basic premium] }
end
