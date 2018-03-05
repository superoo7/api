Rails.application.routes.draw do
  get '/posts/exists'
  resources :posts, only: [:index, :create] do
    collection do
      get '/@:author/:permlink', to: 'posts#show'
      put '/@:author/:permlink', to: 'posts#update'
      delete '/@:author/:permlink', to: 'posts#destroy'
      patch 'refresh/@:author/:permlink', to: 'posts#refresh'
    end
  end

  resources :users, only: [:create]

  get '*foo', to: lambda { |env| [404, {}, [ '{"error": "NOT_FOUND"}' ]] }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
