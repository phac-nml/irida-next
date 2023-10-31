# frozen_string_literal: true

resource :profile, only: %i[show update] do
  scope module: :profiles do
    resource :password, only: %i[edit update]
    resource :account, only: %i[show destroy]
    resource :preferences, only: %i[show update]
    resources :personal_access_tokens, only: %i[index create] do
      member do
        delete :revoke
      end
    end
  end
end
