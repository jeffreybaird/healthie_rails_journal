# frozen_string_literal: true

# Base class for application persistence.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
