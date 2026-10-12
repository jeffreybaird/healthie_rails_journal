# frozen_string_literal: true

require "rails_helper"
require_relative "../support/person_record_examples"

RSpec.describe Provider, type: :model do
  it_behaves_like "a person record"
end
