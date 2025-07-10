# frozen_string_literal: true

if Rails.env.test?
  require 'webmock'

  allowed_hosts = []

  if ENV.key?('BROWSERLESS_HOST')
    allowed_hosts << ENV.fetch('BROWSERLESS_HOST')
    allowed_hosts << 'sapporo'
    allowed_hosts << 'rails-app'
    allowed_hosts << 'vnu'
  end

  WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_hosts)
end
