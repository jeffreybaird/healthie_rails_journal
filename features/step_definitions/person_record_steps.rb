# frozen_string_literal: true

# Model-only acceptance steps for the initial provider and client records.
module PersonRecordSteps
  def save_person(record_type, attributes)
    @person_model = { "Provider" => Provider, "Client" => Client }.fetch(record_type)
    @person_records ||= []
    @person_count_before = @person_model.count
    @attempted_person = @person_model.new(attributes)
    @person_saved = @attempted_person.save
    @person_records << @attempted_person if @person_saved
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

When("I save a {word} with whitespace-only {word}") do |record_type, field|
  save_person(record_type, { name: "Alex Morgan", email: "alex@example.test" }.merge(field.to_sym => " \t\n"))
end

Then("the saved person has name {string} and email {string}") do |name, email|
  expect(@person_saved).to be(true)
  expect(saved_person).to have_attributes(name: name, email: email)
end

Then("the saved person has creation and update timestamps") do
  expect(saved_person).to have_attributes(
    created_at: be_within(5.seconds).of(Time.current),
    updated_at: be_within(5.seconds).of(Time.current)
  )
end

Then("only the first person is stored with email {string}") do |email|
  expect(@person_records.size).to eq(1)
  expect(@person_model.where(email: email).order(:id)).to eq(@person_records)
end

Then("the attempted person is rejected without adding a record") do
  expect(@person_saved).to be(false)
  expect(@attempted_person).not_to be_persisted
  expect(@attempted_person.errors).not_to be_empty
  expect(@person_model.count).to eq(@person_count_before)
end

Then("the attempted person has errors for name and email") do
  expect(@attempted_person.errors[:name]).not_to be_empty
  expect(@attempted_person.errors[:email]).not_to be_empty
end

Then("the provider and client are both stored with their shared email") do
  expect(Provider.find_by!(email: "shared@example.test").name).to eq("Alex Morgan")
  expect(Client.where("lower(email) = ?", "shared@example.test").sole.name).to eq("Sam Rivera")
end
