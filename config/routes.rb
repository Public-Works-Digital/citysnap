Rails.application.routes.draw do
  resources :issues
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check
  root "pages#home"
end
