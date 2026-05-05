# frozen_string_literal: true

resource :profile, only: %i[show update] do
  scope module: :profiles do
    resource :password, only: %i[edit update]
    resource :account, only: %i[show destroy]
    resource :preferences, only: %i[show update]
    resource :experimental_features, only: %i[show update]
    resources :personal_access_tokens, only: %i[index create new] do
      member do
        delete :revoke
        put :rotate
      end
      collection do
        get :list
      end
    end
  end
end
