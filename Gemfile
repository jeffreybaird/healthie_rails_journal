# frozen_string_literal: true

source "https://rubygems.org"
ruby file: ".ruby-version"
gem "puma", "~> 7.2.1"
gem "rails", "~> 8.1.4"
gem "sqlite3", "~> 2.6"
# Security floors also override vulnerable Ruby default-gem versions.
gem "erb", ">= 6.0.4"
gem "rails-html-sanitizer", ">= 1.7.1"
gem "resolv", "~> 0.3.2"

group :development, :test do
  gem "bundler-audit", "~> 0.9", require: false
  gem "capybara", "~> 3.40", require: false
  gem "cucumber-rails", "~> 4.1", require: false
  gem "database_cleaner-active_record", "~> 2.2", require: false
  gem "rspec-rails", "~> 8.0", require: false
  gem "rubocop", "~> 1.91", require: false
  gem "rubocop-rails", "~> 2.38", require: false
  gem "rubocop-rspec", "~> 3.10", require: false
  gem "simplecov", "~> 1.3", require: false
end
