Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "posts#index"

  resource :session
  resources :passwords, param: :token

  resources :posts, only: :show, param: :slug
  get "feed", to: "posts#index", defaults: { format: :atom }, constraints: lambda { |req| req.format == :atom }

  post "signup", to: "subscribers/signups#create", as: :signups
  get "/subscribers/:token/unsubscribe", to: "subscribers/unsubscribes#show", as: :unsubscribe
  patch "/subscribers/:token/unsubscribe", to: "subscribers/unsubscribes#update"

  direct :subscriber_unsubscribe do |subscriber, **opts|
    unsubscribe_url(subscriber.unsubscribe_token, **opts)
  end

  namespace :admin do
    root "dashboards#show"

    resource :author, only: %i[ show edit update ]
    resource :blog, only: %i[ show edit update ]

    resources :posts, param: :slug do
      member do
        patch :publish, to: "posts/statuses#publish"
        patch :unpublish, to: "posts/statuses#unpublish"
        patch "emails/start", to: "posts/email_statuses#start", as: :start_emails
        patch "emails/stop", to: "posts/email_statuses#stop", as: :stop_emails
      end
    end

    resources :subscribers, except: :destroy do
      member do
        patch :activate, to: "subscribers/statuses#activate"
        patch :deactivate, to: "subscribers/statuses#deactivate"
      end
    end
  end

  namespace :action_text, path: nil do
    get "/u/*slug" => "markdown/uploads#show", as: :markdown_upload
    post "/uploads" => "markdown/uploads#create", as: :markdown_uploads
  end
end
