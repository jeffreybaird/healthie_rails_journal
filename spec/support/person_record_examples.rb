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

  it "rejects different records sharing an email address", :aggregate_failures do
    first = described_class.create!(name: "Alex Morgan", email: "shared@example.test")
    second = described_class.new(name: "Sam Rivera", email: "shared@example.test")

    expect(second.save).to be(false)
    expect(second.errors[:email]).not_to be_empty
    expect(described_class.all).to eq([first])
  end

  {
    "omitted name" => { email: "alex@example.test" },
    "omitted email" => { name: "Alex Morgan" },
    "omitted name and email" => {},
    "blank name and email" => { name: "", email: "" },
    "an email without valid syntax" => { name: "Alex Morgan", email: "unformatted-email" },
    "nil name" => { name: nil, email: "alex@example.test" },
    "blank name" => { name: "", email: "alex@example.test" },
    "whitespace name" => { name: " \t\n", email: "alex@example.test" },
    "nil email" => { name: "Alex Morgan", email: nil },
    "blank email" => { name: "Alex Morgan", email: "" },
    "whitespace email" => { name: "Alex Morgan", email: " \t\n" }
  }.each do |description, attributes|
    it "rejects #{description} without persistence", :aggregate_failures do
      record = described_class.new(attributes)

      expect(record.save).to be(false)
      expect(record.errors).not_to be_empty
      expect(described_class.count).to eq(0)
    end
  end

  describe "email syntax" do
    %w[alex+weekly@care.example.test first.last@example.test].each do |email|
      it "accepts representative valid email #{email}" do
        person = described_class.create!(**attributes, email: email)

        expect(person.reload.email).to eq(email)
      end
    end

    ["@example.test", "alex@", "alex rivera@example.test", "alex@example.test\n"].each do |email|
      it "rejects malformed email #{email.inspect}", :aggregate_failures do
        person = described_class.new(**attributes, email: email)

        expect(person.save).to be(false)
        expect(person.errors[:email]).not_to be_empty
        expect(described_class.count).to eq(0)
      end
    end
  end

  describe "email uniqueness within each model" do
    it "rejects a case variant of an existing email", :aggregate_failures do
      first = described_class.create!(attributes)
      duplicate = described_class.new(name: "Sam Rivera", email: first.email.upcase)

      expect(duplicate.save).to be(false)
      expect(duplicate.errors[:email]).not_to be_empty
      expect(described_class.all).to eq([first])
    end

    it "allows an existing person to update while keeping its email" do
      record.update!(name: "Alex Morgan")

      expect(record.reload).to have_attributes(name: "Alex Morgan", email: attributes.fetch(:email))
    end

    it "allows an existing person to change only its email case" do
      expect(record.update(email: record.email.upcase)).to be(true)
    end

    it "rejects changing an email to another person's case variant", :aggregate_failures do
      other = described_class.create!(name: "Alex Morgan", email: "alex@example.test")

      expect(record.update(email: other.email.upcase)).to be(false)
      expect(record.errors[:email]).not_to be_empty
      expect(record.reload.email).to eq(attributes.fetch(:email))
    end

    it "allows the same email in the other person model", :aggregate_failures do
      record
      other_model = described_class == Provider ? Client : Provider
      other = other_model.create!(attributes)

      expect(other.reload.email).to eq(record.email)
      expect(described_class.count).to eq(1)
    end

    it "allows different people to share a name", :aggregate_failures do
      first = described_class.create!(attributes)
      second = described_class.create!(**attributes, email: "other@example.test")

      expect(second.reload.name).to eq(first.name)
      expect(described_class.all).to contain_exactly(first, second)
    end
  end

  describe "database integrity when validations are bypassed" do
    %i[name email].each do |field|
      it "rejects a null #{field}", :aggregate_failures do
        person = described_class.new(**attributes, field => nil)

        expect { person.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
        expect(described_class.count).to eq(0)
      end
    end

    %w[renee@example.test RENEE@EXAMPLE.TEST].each do |email|
      it "rejects duplicate email #{email} at the database boundary", :aggregate_failures do
        record
        duplicate = described_class.new(name: "Alex Morgan", email: email)

        expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
        expect(described_class.all).to eq([record])
      end
    end
  end
end
