# frozen_string_literal: true

When("I request {string} {string}") do |method, path|
  @http_response = Rack::MockRequest.new(Rails.application).request(
    method, path, "action_dispatch.show_exceptions" => :all
  )
end

Then("the HTTP response status is {int}") do |status|
  expect(@http_response.status).to eq(status)
end

Then("the readiness response confirms the database is reachable") do
  expect(JSON.parse(@http_response.body)).to eq("status" => "ok")
end
