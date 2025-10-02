Rails.application.routes.draw do
  resources :issues do
    collection do
      get :public
    end
    resources :comments, only: [ :create, :destroy ]
  end
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check
  root "pages#home"
end
