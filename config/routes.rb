Rails.application.routes.draw do
  resources :posts, only: [:index, :create] do
    collection do
      get 'exists'
      get 'search'
      get 'top'
      patch 'refresh/@:author/:permlink', to: 'posts#refresh', constraints: { author: /[^\/]+/ }
      patch 'moderate/@:author/:permlink', to: 'posts#moderate', constraints: { author: /[^\/]+/ }
      get '/@:author', to: 'posts#author', constraints: { author: /([^\/]+?)(?=\.json|$|\/)/ } # override, otherwise it cannot include dots
      get '/@:author/:permlink', to: 'posts#show', constraints: { author: /[^\/]+/ }
      put '/@:author/:permlink', to: 'posts#update', constraints: { author: /[^\/]+/ }
      delete '/@:author/:permlink', to: 'posts#destroy', constraints: { author: /[^\/]+/ }
    end
  end

  resources :users, only: [:create]

  get '*foo', to: lambda { |env| [404, {}, [ '{"error": "NOT_FOUND"}' ]] }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
