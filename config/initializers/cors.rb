# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # TODO: this MUST be changed to configurable strings. using '*' is unsafe
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :patch, :put]
  end
end
