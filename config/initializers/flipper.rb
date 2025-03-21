# frozen_string_literal: true

Rails.application.configure do
  config.flipper.memoize = ->(request) { !request.path.start_with?('/assets') }
end
