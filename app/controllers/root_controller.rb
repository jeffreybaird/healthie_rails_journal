# frozen_string_literal: true

# Deliberate empty response until an application interface is needed.
class RootController < ApplicationController
  def show
    head :no_content
  end
end
