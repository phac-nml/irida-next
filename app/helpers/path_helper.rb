# frozen_string_literal: true

# Helper for url paths
module PathHelper
  def path_with_params(url, params)
    parsed = URI.parse(url)
    query = if parsed.query
              CGI.parse(parsed.query)
            else
              {}
            end

    params.each do |param, value|
      query[param] = value if value.present?
    end

    parsed.query = URI.encode_www_form(query)
    parsed.to_s
  end
end
