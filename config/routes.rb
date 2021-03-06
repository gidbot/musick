Rails.application.routes.draw do

  root 'static#home'

  get '/auth/spotify', as: 'login'
  get '/auth/spotify/callback', to: 'sessions#create'
  get '/test', to: 'users#test'

  get 'logout' => 'sessions#destroy'

  get 'users/:id/import', to: 'users#import', as: 'import'
  post 'users/:id/import', to: 'users#import_playlists', as: 'playlists_import'
  put 'tracks/:id/vote', to: 'tracks#vote', as: 'vote'

  resources :users
  resources :sessions, only: [:create, :destroy]

  resources :playlists

  resources :tracks

  resources :track_comments,  only: [:create, :destroy]

end
