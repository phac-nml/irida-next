# frozen_string_literal: true

resources :workflow_executions, only: %i[index create destroy] do
  scope '-' do
    put :cancel
  end

  scope module: :workflow_executions, as: :workflow_executions do
    collection do
      resources :submissions, only: %i[create] do
        collection do
          get :pipeline_selection, as: :pipeline_selection
        end
      end
    end
  end
end
