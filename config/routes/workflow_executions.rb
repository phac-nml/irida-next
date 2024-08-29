# frozen_string_literal: true

resources :workflow_executions, only: %i[index create show destroy] do
  member do
    put :cancel
  end

  scope module: :workflow_executions, as: :workflow_executions do
    collection do
      resources :submissions, only: %i[create] do
        collection do
          get :pipeline_selection, as: :pipeline_selection
        end
      end

      resources :metadata, only: [] do
        collection do
          post :fields
        end
      end
    end
  end

  collection do
    get :select
  end
end
