Rails.application.routes.draw do
  root "static_pages#top"
  resources :users, only: %i[new create]
  resources :good_deeds, only: %i[new create index destroy] do
    get :all, on: :collection
  end
  resources :likes, only: %i[create destroy]
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'
end
