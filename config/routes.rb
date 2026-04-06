Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check

  root "posts#index"

  get "feed", to: "posts#index", defaults: { format: :atom }, constraints: lambda { |req| req.format == :atom }
  resources :posts, only: :show, param: :slug
  post "signup", to: "subscribers/signups#create", as: :signups

  namespace :admin do
    root "posts#index"

    resources :posts, param: :slug do
      member do
        patch :publish, to: "posts/statuses#publish"
        patch :unpublish, to: "posts/statuses#unpublish"
      end
    end
  end

  get "/subscribers/:token/unsubscribe", to: "subscribers/unsubscribes#unsubscribe", as: :unsubscribe

  direct :subscriber_unsubscribe do |subscriber, **opts|
    unsubscribe_url(subscriber.unsubscribe_token, **opts)
  end
end
