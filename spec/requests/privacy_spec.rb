# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Request parameter privacy", type: :request do
  subject(:filtered) { parameter_filter.filter(parameters) }

  let(:parameter_filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }
  let(:parameters) do
    {
      "note" => { "title" => "Confidential release plan" },
      "journal_entry" => { "content" => "Synthetic private journal reflection that remains in application memory." },
      "client" => { "name" => "Synthetic Private Client", "email" => "synthetic.private@example.test" },
      "password" => "private-password",
      "api_token" => "private-token",
      "secret_key" => "private-key",
      "page" => "2"
    }
  end

  it "redacts nested note content from request logging" do
    expect(filtered.fetch("note")).to eq("title" => "[FILTERED]")
  end

  it "redacts nested journal content from request logging" do
    expect(filtered.fetch("journal_entry")).to eq("content" => "[FILTERED]")
  end

  it "redacts client personal details from request logging" do
    expect(filtered.fetch("client")).to eq("name" => "[FILTERED]", "email" => "[FILTERED]")
  end

  it "redacts standard credential fields" do
    expect(filtered.slice("password", "api_token", "secret_key").values).to eq(Array.new(3, "[FILTERED]"))
  end

  it "keeps harmless request metadata useful" do
    expect(filtered.fetch("page")).to eq("2")
  end

  it "filters a copy without changing the application's original parameters" do
    original_parameters = parameters.deep_dup

    parameter_filter.filter(parameters)

    expect(parameters).to eq(original_parameters)
  end
end
