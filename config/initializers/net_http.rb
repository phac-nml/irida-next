# frozen_string_literal: true

Net::HTTP.class_eval do
  alias_method :_use_ssl=, :use_ssl=

  def use_ssl=(boolean)
    if ENV.key?('NIX_SSL_CERT_FILE')
      self.ca_file = ENV['NIX_SSL_CERT_FILE']
      self.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
    self._use_ssl = boolean
  end
end
