# frozen_string_literal: true

# Stores a client's freeform journal content and its timestamps.
class JournalEntry < ApplicationRecord
  belongs_to :client

  validates :content, presence: true, length: { minimum: 50 }
end
