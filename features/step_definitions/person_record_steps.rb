# frozen_string_literal: true

# Model-only acceptance steps for the initial provider and client records.
module PersonRecordSteps
  def save_person(record_type, attributes)
    @person_model = { "Provider" => Provider, "Client" => Client }.fetch(record_type)
    @person_records ||= []
    @person_records << @person_model.create!(attributes)
  end

  def saved_person
    @person_model.find(@person_records.last.id)
  end
end

World(PersonRecordSteps)

When("I save a {word} with name {string} and email {string}") do |record_type, name, email|
  save_person(record_type, name: name, email: email)
end

When("I save a {word} without name or email") do |record_type|
  save_person(record_type, {})
end

Then("the saved person has name {string} and email {string}") do |name, email|
  expect(saved_person).to have_attributes(name: name, email: email)
end

Then("the saved person has creation and update timestamps") do
  expect(saved_person).to have_attributes(
    created_at: be_within(5.seconds).of(Time.current),
    updated_at: be_within(5.seconds).of(Time.current)
  )
end

Then("both people are stored with email {string}") do |email|
  expect(@person_model.where(email: email).order(:id)).to eq(@person_records)
end

Then("the saved person has no name or email") do
  expect(saved_person).to have_attributes(name: nil, email: nil)
end
