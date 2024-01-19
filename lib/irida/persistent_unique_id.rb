# frozen_string_literal: true

module Irida
  # Module to encapsulate persistent unique id for IRIDA
  module PersistentUniqueId
    module_function

    FORMAT = '%<prefix>s_%<model_prefix>s_%<base32_string>s'

    def generate(object = nil)
      return unless object

      prefix = 'GSP' # TODO: pull from config
      model_prefix = model.class.model_prefix

      current_time = Time.now.utc

      base32_string = time_to_base32(current_time)
      format(FORMAT, prefix:, model_prefix:, base32_string:)
    end

    def time_to_base32(time)
      base32_string = Base32.encode32(time.year - 2000, 2)
      base32_string << Base32.encode32(time.month, 1)
      base32_string << Base32.encode32(time.day, 1)
      base32_string << Base32.encode32(Integer(time.seconds_since_midnight * 1024), 6)
    end
  end
end
