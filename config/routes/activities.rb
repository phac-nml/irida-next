# frozen_string_literal: true

scope '-' do
  resources :activities, controller: 'activities', only: %i[show]
end
