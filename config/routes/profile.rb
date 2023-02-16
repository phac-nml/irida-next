# frozen_string_literal: true

resource :profile, only: %i[show update] do
  scope module: :profiles do
    resource :password, only: %i[edit update]
  end
end
