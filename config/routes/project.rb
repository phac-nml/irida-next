# frozen_string_literal: true

constraints(::Constraints::ProjectUrlConstrainer.new) do
  scope(path: '*namespace_id/:project_id',
        constraints: { namespace_id: Irida::PathRegex.full_namespace_route_regex,
                       project_id: Irida::PathRegex.project_route_regex },
        module: :projects,
        as: :namespace_project) do
    get '/', action: :show
    patch '/', action: :update
    put '/', action: :update
    delete '/', action: :destroy

    # Begin on /-/ scope.
    # Use this for all project routes.
    scope '-' do
      match :activity, via: %i[get post]
      get :edit
      post :transfer
      resources :members, only: %i[create destroy index new update]
      resources :attachments, only: %i[create destroy index new] do
        get :new_destroy
      end

      resource :file_import, module: :samples, only: %i[create new]

      resources :bots, only: %i[create destroy index new] do
        get :destroy_confirmation
        resources :personal_access_tokens, module: :bots, only: %i[index new create] do
          member do
            delete :revoke
            get :revoke_confirmation
          end
        end
      end

      if Irida::Pipelines.instance.available_pipelines.any?
        resources :automated_workflow_executions

        resources :workflow_executions, only: %i[index destroy show edit update] do
          member do
            put :cancel
          end
          collection do
            get :select
          end
        end
      end

      resources :group_links, only: %i[create destroy update index new]
      resources :metadata_templates do
        collection do
          get :list
        end
      end
      resources :samples do
        scope module: :samples, as: :samples do
          collection do
            resource :clone, only: %i[create new]
            resource :transfer, only: %i[create new]
            resource :file_import, module: :metadata, only: %i[create new]
            resource :deletion, only: %i[destroy new] do
              delete :destroy_multiple
            end
          end
        end
        collection do
          get :select
          post :list
          post :search
          post :metadata_template
        end
        resources :attachments, module: :samples, only: %i[new create destroy] do
          scope module: :attachments, as: :attachments do
            collection do
              resource :concatenation, only: %i[create new]
            end
            collection do
              resource :deletion, only: %i[new destroy]
            end
          end
          get :new_destroy
        end
        resource :metadata, module: :samples, only: %i[new edit destroy] do
          scope module: :metadata, as: :metadata do
            collection do
              resource :field, only: %i[update create] do
                get :editable
                patch :update_value
              end
            end
            collection do
              resource :deletion, only: %i[new destroy]
            end
          end
        end

        get :view_history_version
      end

      get '/history' => 'history#index', as: :history
      get '/history/new' => 'history#new', as: :view_history
    end
  end
end
