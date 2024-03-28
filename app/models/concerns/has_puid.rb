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
  end

  class_methods do
    def model_prefix
      raise NotImplementedError
    end
  end

  def generate_puid
    return unless puid.nil?

    self.puid = Irida::PersistentUniqueId.generate(self)
  end
end
