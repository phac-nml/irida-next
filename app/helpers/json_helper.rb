# frozen_string_literal: true

# View helper to convert string json to hash
module JsonHelper
  def json_string_to_hash(json_string)
    return unless json_string.is_a?(String) && !json_string.scan(/[{}=>:]/).empty?

    JSON.parse json_string.gsub('=>', ':')
  end
end
