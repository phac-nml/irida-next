# frozen_string_literal: true

resources :workflow_executions, only: %i[create show] do
  scope module: :workflow_executions, as: :workflow_executions do
    collection do
      resources :submissions, only: %i[new] do
        collection do
          get :pipeline_selection, as: :pipeline_selection
        end
      end
    end
  end
  scope module: :workflow_executions do
    resources :samples, path: :samples, only: %i[index]
  end
end
