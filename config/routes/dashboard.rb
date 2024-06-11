# frozen_string_literal: true

resource :dashboard, controller: 'dashboard', only: [] do
  scope module: :dashboard do
    resources :projects, only: [:index]
    resources :groups, only: [:index]
  end

  root to: 'dashboard/projects#index'
end
