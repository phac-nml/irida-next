# frozen_string_literal: true

namespace :ga4gh_wes do
  # the following can defined in credentials to configure the client
  # ga4gh_wes:
  #   oauth_token: <some oauth token>
  #   headers: { '<some header key>': '<some header value>' }
  #   server_url_endpoint: 'https://localhost:7500/ga4gh/wes/v1/'
  desc 'request service_info from ga4gh_wes server'
  task service_info: :environment do
    ga4gh_client = Integrations::Ga4ghWesApi::V1::Client.new
    ga4gh_client.service_info
  end
end
