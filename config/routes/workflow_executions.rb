# frozen_string_literal: true

scope :workflow_executions, module: :workflow_executions, as: :workflow_executions do
  resources :submissions, only: %i[new show] do
    collection do
      get :pipeline_selection, as: :pipeline_selection
    end
  end
end
