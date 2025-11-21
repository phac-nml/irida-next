# frozen_string_literal: true

# Concern to make a Model have a Persistent Unique Identifier
module HasPuid
  extend ActiveSupport::Concern

  included do
    before_validation :generate_puid, on: :create

    def dup
      clone = super
      clone.puid = nil # set clone puid to nil as puid is supposed to be unique

      clone
    end

    # override create_or_update so that we can retry when puid conflict is encountered.
    # This should only occur when >1 record are created within 0.0817795224076 milliseconds of each other.
    def create_or_update(**options, &)
      return super unless new_record?

      retry_count = 0
      begin
        ActiveRecord::Base.transaction(requires_new: true) do
          return super
        end
      rescue ActiveRecord::RecordNotUnique => e
        raise e unless e.message.match(/Key \(puid\)=\(.*\) already exists./)

        retry_count += 1
        raise e if retry_count > 10 # Prevent infinite loops

        Rails.logger.info(
          "PUID conflict encountered for #{self.class}, regenerating PUID and attempting to save again."
        )

        # Add a small time offset to ensure we generate a different PUID on retry
        time_offset = retry_count * 0.01 # 10 milliseconds per retry
        generate_puid(force: true, time_offset:)
        retry
      end
    end
  end

  class_methods do
    def model_prefix
      raise NotImplementedError
    end
  end

  def generate_puid(force: false, time_offset: 0)
    return unless force || puid.nil?

    time = Time.now.utc + time_offset
    self.puid = Irida::PersistentUniqueId.generate(self, time:)
  end
end
