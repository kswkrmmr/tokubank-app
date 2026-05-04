Rails.application.routes.draw do
  get "good_deeds/new"
  get "good_deeds/create"
  root "static_pages#top"
  resources :users, only: %i[new create]
  resources :good_deeds, only: %i[new create]
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'
end
