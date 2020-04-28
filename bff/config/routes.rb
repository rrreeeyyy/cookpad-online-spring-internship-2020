Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :v1 do
    resources :recipes
    resources :users do
      resources :recipes, only: :index, controller: :user_recipes
    end
    resources :tsukurepos
  end

  resource :hello, only: %i(show)
end
