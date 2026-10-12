# frozen_string_literal: true

# Stores a client's name and email address.
class Client < ApplicationRecord
  has_many :provider_client_relationships, dependent: nil
  has_many :providers, through: :provider_client_relationships
  has_many :journal_entries, dependent: nil

  validates :name, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
end
