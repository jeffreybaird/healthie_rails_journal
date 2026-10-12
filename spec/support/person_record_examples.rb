# frozen_string_literal: true

RSpec.shared_examples "a person record" do
  include ActiveSupport::Testing::TimeHelpers

  let(:saved_at) { Time.zone.local(2026, 1, 15, 12) }
  let(:updated_at) { saved_at + 1.hour }
  let(:attributes) { { name: "Renée O'Neil", email: "renee@example.test" } }
  let(:updated_attributes) { { name: "Alex Rivera", email: "rivera@example.test" } }
  let(:record) { described_class.create!(attributes) }

  around { |example| travel_to(saved_at) { example.run } }

  it "uses the application's ordinary Active Record persistence base" do
    expect(described_class.superclass).to eq(ApplicationRecord)
  end

  it "persists a representative name and email with Rails timestamps" do
    expect(described_class.find(record.id)).to have_attributes(
      **attributes, created_at: saved_at, updated_at: saved_at
    )
  end

  it "updates stored attributes and updated_at while preserving created_at" do
    record
    travel_to(updated_at)
    record.update!(updated_attributes)
    expect(record.reload).to have_attributes(**updated_attributes, created_at: saved_at, updated_at: updated_at)
  end

  it "allows different records to share an email address" do
    first = described_class.create!(name: "Alex Morgan", email: "shared@example.test")
    second = described_class.create!(name: "Sam Rivera", email: "shared@example.test")

    expect(described_class.where(email: "shared@example.test").order(:id)).to eq([first, second])
  end

  {
    "omitted name" => { email: "alex@example.test" },
    "omitted email" => { name: "Alex Morgan" },
    "omitted name and email" => {},
    "blank name and email" => { name: "", email: "" },
    "an email without format restrictions" => { name: "Alex Morgan", email: "unformatted-email" }
  }.each do |description, attributes|
    it "persists #{description}" do
      record = described_class.create!(attributes)

      expect(record.reload).to have_attributes(
        name: attributes[:name], email: attributes[:email]
      )
    end
  end
end
