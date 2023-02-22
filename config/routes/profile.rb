# frozen_string_literal: true

resource :profile, only: %i[show update] do
  scope module: :profiles do
    resource :password, only: %i[edit update]
    resource :account, only: %i[show update]
  end
end
