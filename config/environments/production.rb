# frozen_string_literal: true

Rails.application.configure do
  config.eager_load = true
  config.enable_reloading = false
  config.consider_all_requests_local = false
  # Image source is immutable; migrations update the volume, not db/schema.rb.
  config.active_record.dump_schema_after_migration = false
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE") do
    ENV.fetch("SECRET_KEY_BASE_DUMMY", nil) && "build-only-dummy-secret"
  end
  # Caddy terminates HTTPS; internal Docker readiness probes use plain HTTP.
  config.assume_ssl = true
  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { ["/health", "/up"].include?(request.path) } } }
  config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new($stdout))
end
