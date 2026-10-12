# frozen_string_literal: true

# Translates HTTP input and service results; persistence belongs to Notes services.
class NotesController < ApplicationController
  def index
    render_index
  end

  def create
    attributes = params.expect(note: [:title]).to_h
    result = Notes::Create.call(attrs: attributes)
    return redirect_to notes_path, status: :see_other if result.success?

    render_index(note: Note.new(attributes), errors: result.failure.last, status: :unprocessable_content)
  end

  def archive
    result = Notes::Archive.call(id: params[:id])
    return head :not_found if result.failure?

    redirect_to notes_path, status: :see_other
  end

  private

  def render_index(note: Note.new, errors: {}, status: :ok)
    listing = Notes::List.call(page: params.fetch(:page, 1))
    render :index, locals: { note:, listing:, errors: }, status:
  end
end
