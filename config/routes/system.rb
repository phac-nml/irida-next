# frozen_string_literal: true

resource :system, only: [] do
  scope module: :system do
    resources :initial_setup, only: [] do
      member do
        get :update
      end
    end
  end
end
