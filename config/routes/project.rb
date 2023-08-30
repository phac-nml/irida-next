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
      get :activity
      get :edit
      post :transfer
      resources :members, only: %i[create destroy index new update]
      resources :group_links, only: %i[create destroy update index]
      resources :samples do
        scope module: :samples, as: :samples do
          collection do
            resource :transfer, only: %i[create new]
          end
        end
        resources :attachments, module: :samples, only: %i[create update destroy] do
          member do
            get :download
          end
        end
      end
    end
  end
end
