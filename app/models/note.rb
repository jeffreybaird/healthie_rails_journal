# frozen_string_literal: true

# Recoverable content; archived rows remain available to deliberate recovery tools.
class Note < ApplicationRecord
  validates :title, presence: true
  scope :kept, -> { where(archived_at: nil) }
end
