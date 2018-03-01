Rails.application.routes.draw do
  get '/posts/exists'
  resources :posts, only: [:index, :create] do
    collection do
      get '/@:author/:permlink', to: 'posts#show'
      patch '/@:author/:permlink', to: 'posts#update'
    end
  end

  get '*foo', to: lambda { |env| [404, {}, [ '{"error": "NOT_FOUND"}' ]] }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
