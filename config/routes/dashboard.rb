# frozen_string_literal: true

resource :dashboard, controller: 'dashboard', only: [] do
  scope module: :dashboard do
    resources :projects, only: [:index]
    resources :groups, only: [:index]
    resources :workflow_executions, only: [:index] if Irida::Pipelines.instance.available_pipelines.any?
  end

  root to: 'dashboard/projects#index'
end
