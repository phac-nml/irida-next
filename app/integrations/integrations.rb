# frozen_string_literal: true

# module responsible for all integrations
# TODO: is this file actually needed? How are modules setup??
# currently using with following in rails console
# `ga4gh_client = Ga4ghWesApi::Client.new`
# above creates error, then
# `ga4gh_client = Integrations::Ga4ghWesApi::Client.new`
# creates client, just doing second line doesn't work
module Integrations
end
