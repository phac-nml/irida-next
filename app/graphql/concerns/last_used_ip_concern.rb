# frozen_string_literal: true

# Concern for keeping track of the last 5 used ips personal access token
module LastUsedIpConcern # rubocop:disable GraphQL/ObjectDescription
  include ActiveSupport::Concern

  # Adds the given IP address to the list of last used ips for the given personal access token,
  # if it is not already present. If it is a new IP address, an email notification will be sent to the user
  # associated with the personal access token.
  def update_last_used_ips(personal_access_token, ip_address) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return if personal_access_token.nil? || ip_address.nil? || personal_access_token.integration?

    last_used_ip_addresses = personal_access_token.last_used_ips || []
    ip_address = IPAddr.new(ip_address)
    last_used_ips_limit = 5

    if last_used_ip_addresses.empty?
      personal_access_token.update(last_used_ips: [ip_address])
    else
      unless last_used_ip_addresses.include?(ip_address)
        last_used_ip_addresses.shift if last_used_ip_addresses.length >= last_used_ips_limit
        last_used_ip_addresses.push(ip_address)

        personal_access_token.update(last_used_ips: last_used_ip_addresses)
        # send email to user about new IP address being added to their token and that
        # they should either revoke or rotate the token if they do not recognize the IP address
        PersonalAccessTokenMailer.new_ip_address_for_token(personal_access_token, ip_address.to_s).deliver_later
      end
    end
  end
end
