# frozen_string_literal: true

# Readiness includes database connectivity.
class HealthController < ApplicationController
  def show
    ActiveRecord::Base.connection.execute("SELECT 1")
    render json: { status: "ok" }
  end
end
