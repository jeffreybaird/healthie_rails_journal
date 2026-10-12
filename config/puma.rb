# frozen_string_literal: true

max_threads = Integer(ENV.fetch("RAILS_MAX_THREADS", 5))
threads 1, max_threads
bind "tcp://0.0.0.0:#{ENV.fetch("PORT", 4000)}"
environment ENV.fetch("RAILS_ENV", "development")
