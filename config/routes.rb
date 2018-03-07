Rails.application.routes.draw do
  get '/posts/exists'
  resources :posts, only: [:index, :create] do
    collection do
      get '/@:author/:permlink', to: 'posts#show', constraints: { author: /[^\/]+/ } # override, otherwise it cannot include dots
      put '/@:author/:permlink', to: 'posts#update', constraints: { author: /[^\/]+/ }
      delete '/@:author/:permlink', to: 'posts#destroy', constraints: { author: /[^\/]+/ }
      patch 'refresh/@:author/:permlink', to: 'posts#refresh', constraints: { author: /[^\/]+/ }
      patch 'hide/@:author/:permlink', to: 'posts#hide', constraints: { author: /[^\/]+/ }
    end
  end

  resources :users, only: [:create]

  get '*foo', to: lambda { |env| [404, {}, [ '{"error": "NOT_FOUND"}' ]] }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
