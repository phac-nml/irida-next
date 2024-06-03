# frozen_string_literal: true

module Irida
  # Module to encapsulate persistent unique id for IRIDA
  module PersistentUniqueId
    mattr_accessor :app_prefix

    GenerationError = Class.new(StandardError)

    module_function

    FORMAT = '%<app_prefix>s_%<model_prefix>s_%<base32_string>s'

    def generate(object = nil, object_class: nil, time: Time.now.utc)
      return if object.nil? && object_class.nil?

      begin
        model_prefix = if object.present?
                         object.class.model_prefix
                       else
                         object_class.model_prefix
                       end
      rescue NoMethodError
        raise GenerationError
      end

      base32_string = time_to_base32(time)
      format(FORMAT, app_prefix:, model_prefix:, base32_string:)
    end

    def time_to_base32(time)
      base32_string = Base32.encode32(time.year - 2000, 2)
      base32_string << Base32.encode32(time.month, 1)
      base32_string << Base32.encode32(time.day, 1)
      base32_string << Base32.encode32(Integer(time.seconds_since_midnight * 1024), 6)
    end

    def valid_puid?(puid, object_class = nil)
      re = /\A#{app_prefix}_#{object_class.model_prefix}_([A-Z]|[2-7]){10}\z/
      re.match?(puid)
    end
  end
end
