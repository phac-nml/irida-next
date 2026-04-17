# frozen_string_literal: true

# Query Concern
module WhitelistIpConcern # rubocop:disable GraphQL/ObjectDescription
  include ActiveSupport::Concern

  def whitelist_ip(personal_access_token, ip_address)
    return if personal_access_token.nil? || ip_address.nil?

    if personal_access_token.ip_addresses.empty?
      personal_access_token.update(ip_addresses: [ip_address])
    else
      unless personal_access_token.ip_addresses.include?(ip_address)
        personal_access_token.update(ip_addresses: personal_access_token.ip_addresses + [ip_address])
        # send email to user about new IP address being added to their token and that
        # they should either revoke or rotate the token if they do not recognize the IP address
        PersonalAccessTokenMailer.new_ip_address_for_token(personal_access_token, ip_address).deliver_later
      end
    end
  end
end
