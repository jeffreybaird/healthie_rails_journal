# frozen_string_literal: true

module Notes
  # Creates valid content and its durable audit in one transaction.
  module Create
    extend Dry::Monads[:result]

    def self.call(attrs:)
      note = Note.new(attrs)
      return Failure([:validation, note.errors.to_hash]) unless note.valid?

      Note.transaction { persist(note) }
      Success(note)
    end

    def self.persist(note)
      note.save!
      AuditLog.create!(event: "notes.created", record_id: note.id)
      ActiveRecord.after_all_transactions_commit do
        ActiveSupport::Notifications.instrument("notes.created", note_id: note.id)
      end
    end
    private_class_method :persist
  end
end
