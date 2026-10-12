# frozen_string_literal: true

module Notes
  # Bounded, stable pagination over recoverable content that is still visible.
  module List
    def self.call(page: 1, per_page: 25)
      page = page.to_i.clamp(1, Float::INFINITY)
      per_page = per_page.to_i.clamp(1, 100)
      notes = Note.kept
      items = notes.order(created_at: :desc, id: :desc).limit(per_page).offset((page - 1) * per_page)
      { items: items.to_a, page:, per_page:, total: notes.count }
    end
  end
end
