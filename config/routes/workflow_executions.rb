# frozen_string_literal: true

resources :workflow_executions, only: %i[index create show destroy edit update] do
  member do
    put :cancel
    get :destroy_confirmation
  end

  scope module: :workflow_executions, as: :workflow_executions do
    collection do
      resources :submissions, only: %i[create] do
        collection do
          get :pipeline_selection, as: :pipeline_selection
        end
      end
      resources :file_selector, only: %i[new create]
      resources :metadata, only: [] do
        collection do
          post :fields
        end
      end
    end
  end

  collection do
    get :select
    get :destroy_multiple_confirmation
    post :destroy_multiple
    post :list
  end
end
