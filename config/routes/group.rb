# frozen_string_literal: true

constraints(::Constraints::GroupUrlConstrainer.new) do
  scope(path: '-/groups/*id',
        controller: :groups,
        constraints: { id: Irida::PathRegex.full_namespace_route_regex }) do
    scope(path: '-') do
      get :edit, as: :edit_group
      scope module: :groups do
        resources :members, only: %i[create destroy index new]
      end
    end

    get '/', action: :show, as: :group_canonical
  end

  scope(path: '*id',
        as: :group,
        constraints: { id: Irida::PathRegex.full_namespace_route_regex },
        controller: :groups) do
    get '/', action: :show
    delete '/', action: :destroy
    patch '/', action: :update
    put '/', action: :update
  end
end
