# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Application boundary", type: :request do
  it "responds deliberately at the root without rendering a feature", :aggregate_failures do
    get "/"

    expect(response).to have_http_status(:no_content)
    expect(response.body).to be_empty
  end
end
