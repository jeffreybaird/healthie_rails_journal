# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationRecord, type: :model do
  it "rejects direct construction of the abstract persistence base" do
    expect { described_class.new }.to raise_error(NotImplementedError)
  end
end
