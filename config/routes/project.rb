# frozen_string_literal: true

constraints(::Constraints::ProjectUrlConstrainer.new) do
  scope(path: '*namespace_id/:id',
        constraints: { namespace_id: Irida::PathRegex.full_namespace_route_regex,
                       id: Irida::PathRegex.project_route_regex },
        module: :projects,
        as: :namespace_project) do
    get '/', action: :show
    post '/', action: :update
    put '/', action: :update

    # Begin on /-/ scope.
    # Use this for all project routes.
    scope '-' do
      get :activity
      get :edit
      post :transfer
    end
  end
end
