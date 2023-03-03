# frozen_string_literal: true

constraints(::Constraints::ProjectUrlConstrainer.new) do # rubocop:disable Style/RedundantConstantBase
  scope(path: '*namespace_id',
        as: :namespace,
        namespace_id: Irida::PathRegex.full_namespace_route_regex) do
    scope(path: ':project_id',
          constraints: { project_id: Irida::PathRegex.project_route_regex },
          module: :projects,
          as: :project) do
      # Begin on /-/ scope.
      # Use this for all project routes.
      scope '-' do
        get :activity
        get :edit
      end
    end

    resources(:projects,
              path: '/',
              constraints: { id: Irida::PathRegex.project_route_regex },
              only: %i[show update])
  end
end
