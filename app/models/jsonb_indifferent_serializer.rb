# frozen_string_literal: true

# Allows jsonb serialized data to behave like a hash
class JsonbIndifferentSerializer
  def self.dump(obj)
    obj.to_json
  end

  def self.load(str_json)
    hsh = JSON.parse(str_json) if str_json.instance_of?(String)
    ActiveSupport::HashWithIndifferentAccess.new(hsh)
  end
end
