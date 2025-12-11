# frozen_string_literal: true

ActionDispatch::Routing::Mapper.class_eval do
  protected

  def devise_registration(mapping, controllers)
    path_names = {
      new: mapping.path_names[:sign_up],
      edit: mapping.path_names[:edit],
      cancel: mapping.path_names[:cancel]
    }

    resource :registration,
             only: %i[new create edit update destroy],
             path: mapping.path_names[:registration],
             path_names: path_names,
             controller: controllers[:registrations] do
      get :cancel
    end
  end
end
