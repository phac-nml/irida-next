# frozen_string_literal: true

resource :workflow_executions, only: %i[show update] do
  scope module: :workflows do
    resource :selection, only: %i[show]
  end
end
