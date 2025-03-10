# frozen_string_literal: true

resources :attachment, controller: 'attachment', only: %i[show], param: :attachment_id, path: 'attachment'
