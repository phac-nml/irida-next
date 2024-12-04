# frozen_string_literal: true

Rails.application.configure do
  config.lookbook.component_paths = [
    Rails.root.join('../app/components')
  ]
  config.lookbook.preview_paths = [
    Rails.root.join('test/components/previews')
  ]
end
