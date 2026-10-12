# frozen_string_literal: true

module Notes
  # Archives kept content without destroying it or duplicating audit events.
  module Archive
    extend Dry::Monads[:result]

    def self.call(id:)
      Note.transaction do
        note = Note.kept.find_by(id:)
        next Failure([:not_found]) unless note

        archive(note)
        Success(note)
      end
    end

    def self.archive(note)
      note.update!(archived_at: Time.current)
      AuditLog.create!(event: "notes.archived", record_id: note.id)
      ActiveRecord.after_all_transactions_commit do
        ActiveSupport::Notifications.instrument("notes.archived", note_id: note.id)
      end
    end
    private_class_method :archive
  end
end
