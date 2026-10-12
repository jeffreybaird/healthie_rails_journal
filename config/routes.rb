# frozen_string_literal: true

Rails.application.routes.draw do
  get "/health", to: "health#show"
  get "/up", to: "health#show"
  resources :notes, only: %i[index create] do
    patch :archive, on: :member
  end
  root "notes#index"
end
