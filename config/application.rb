# frozen_string_literal: true

require_relative "boot"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
Bundler.require(*Rails.groups)

# Application namespace.
module HealthieRailsJournal
  # Configures the single-database Rails service.
  class Application < Rails::Application
    config.load_defaults 8.1
    config.filter_parameters += %i[title password secret token key authorization]
    # This service uses one SQLite database. No background workers or Solid
    # Queue/Cache/Cable databases are generated or booted implicitly.
    config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  end
end
