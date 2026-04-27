# frozen_string_literal: true

# Concern for whitelisting ip addresses for a personal access token
module WhitelistIpConcern # rubocop:disable GraphQL/ObjectDescription
  include ActiveSupport::Concern

  # Adds the given IP address to the list of whitelisted IP addresses for the given personal access token,
  # if it is not already present. If it is a new IP address, an email notification will be sent to the user
  # associated with the personal access token.
  def whitelist_ip(personal_access_token, ip_address)
    return if personal_access_token.nil? || ip_address.nil? || personal_access_token.integration?

    existing_ip_addresses = personal_access_token.ip_addresses || []
    ip_address = IPAddr.new(ip_address)

    if existing_ip_addresses.empty?
      personal_access_token.update(ip_addresses: [ip_address])
    else
      unless existing_ip_addresses.include?(ip_address)
        personal_access_token.update(ip_addresses: existing_ip_addresses + [ip_address])
        # send email to user about new IP address being added to their token and that
        # they should either revoke or rotate the token if they do not recognize the IP address
        PersonalAccessTokenMailer.new_ip_address_for_token(personal_access_token, ip_address.to_s).deliver_later
      end
    end
  end
end
