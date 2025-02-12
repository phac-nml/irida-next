# frozen_string_literal: true

constraints(::Constraints::GroupUrlConstrainer.new) do
  scope(path: '-/groups/*id',
        controller: :groups,
        constraints: { id: Irida::PathRegex.full_namespace_route_regex }) do
    scope(path: '-') do
      get :edit, as: :edit_group
    end

    get '/', action: :show, as: :group_canonical
  end

  scope(path: '-/groups/*group_id/-',
        module: :groups,
        as: :group,
        constraints: { group_id: Irida::PathRegex.full_namespace_route_regex }) do
    resources :members, only: %i[create destroy index new update]

    resources :bots, only: %i[create destroy index new] do
      get :destroy_confirmation
      resources :personal_access_tokens, module: :bots, only: %i[index new create] do
        member do
          get :revoke_confirmation
          delete :revoke
        end
      end
    end

    if Irida::Pipelines.instance.available_pipelines.any?
      resources :workflow_executions, only: %i[index] do
        member do
          put :cancel
        end
        collection do
          get :select
        end
      end
    end

    resources :attachments, only: %i[create destroy index new] do
      get :new_destroy
    end
    resources :group_links, only: %i[create destroy update index new]
    resources :metadata_templates do
      collection do
        get :list
      end
    end
    resources :samples, only: %i[index] do
      scope module: :samples, as: :samples do
        collection do
          resource :file_import, module: :metadata, only: %i[create new]
        end
      end
      collection do
        get :select
        post :search
      end
    end
    resources :subgroups, only: %i[index]
    resources :shared_namespaces, only: %i[index]

    get '/history' => 'history#index', as: :history
    get '/history/new' => 'history#new', as: :view_history
  end

  scope(path: '*id',
        as: :group,
        constraints: { id: Irida::PathRegex.full_namespace_route_regex },
        controller: :groups) do
    get '/', action: :show
    delete '/', action: :destroy
    patch '/', action: :update
    put '/', action: :update
    put :transfer
    match :activity, via: %i[get post]
  end
end
