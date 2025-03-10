# frozen_string_literal: true

resources :attachment, controller: 'attachment', only: %i[show destroy], param: :attachment_id, path: 'attachment'
