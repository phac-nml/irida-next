# frozen_string_literal: true

# This rake files is temporary. It is used for testing integrations.
namespace :integrations do
  desc 'do some calls to ga4gh wes'
  task info: :environment do
    ga4gh_client = Ga4ghWesApi::Client.new
    ret = ga4gh_client.service_info
    puts JSON.pretty_generate(ret)
  end

  task runs: :environment do
    ga4gh_client = Ga4ghWesApi::Client.new
    ret = ga4gh_client.runs
    puts JSON.pretty_generate(ret)
  end
end
