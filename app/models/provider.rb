# frozen_string_literal: true

# Stores a provider's name and email address.
class Provider < ApplicationRecord
  has_many :provider_client_relationships, dependent: nil
  has_many :clients, through: :provider_client_relationships
  has_many :journal_entries, through: :clients

  validates :name, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
end
