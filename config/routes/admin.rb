# frozen_string_literal: true

resource :admin, only: [] do
  scope module: :admin do
    resources :initial_setup, only: [] do
      member do
        get :update
      end
    end
  end
end
