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

    # override save! so that we can retry when puid conflict is encountered.
    # This should only occur when >1 record are created within 0.0817795224076 milliseconds of each other.
    def save!
      super
    rescue ActiveRecord::RecordNotUnique => e
      raise e unless e.message.match(/Key \(puid\)=\(.*\) already exists./)

      Rails.logger.info("Puid conflict encountered for #{self.class}, regerating Puid and attempting to save again.")
      generate_puid(force: true)
      save!
    end
  end

  class_methods do
    def model_prefix
      raise NotImplementedError
    end
  end

  def generate_puid(force: false)
    return unless force || puid.nil?

    self.puid = Irida::PersistentUniqueId.generate(self)
  end
end
