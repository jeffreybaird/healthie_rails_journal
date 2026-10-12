# frozen_string_literal: true

Rails.application.routes.draw do
  get "/health", to: "health#show"
  get "/up", to: "health#show"
  root "root#show"
end
