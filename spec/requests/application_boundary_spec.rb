# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Application boundary", type: :request do
  it "responds deliberately at the root without rendering a feature", :aggregate_failures do
    get "/"

    expect(response).to have_http_status(:no_content)
    expect(response.body).to be_empty
  end

  it "does not expose the former note list" do
    get "/notes", env: { "action_dispatch.show_exceptions" => :all }

    expect(response).to have_http_status(:not_found)
  end

  it "does not accept former note creation requests" do
    post "/notes", params: { note: { title: "Synthetic note" } },
                   env: { "action_dispatch.show_exceptions" => :all }

    expect(response).to have_http_status(:not_found)
  end

  it "does not accept former note archive requests" do
    patch "/notes/1/archive", env: { "action_dispatch.show_exceptions" => :all }

    expect(response).to have_http_status(:not_found)
  end

  it "removes note controller routes" do
    controllers = Rails.application.routes.routes.map { |route| route.defaults[:controller] }

    expect(controllers).not_to include("notes")
  end

  it "removes the note model, controller, services and exclusive audit model", :aggregate_failures do
    %i[Note NotesController Notes AuditLog].each do |constant|
      expect(Object.const_defined?(constant)).to be(false), "Expected #{constant} to be removed"
    end
  end
end
