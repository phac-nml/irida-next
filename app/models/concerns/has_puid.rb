# frozen_string_literal: true

# Concern to make a Model have a Persistent Unique Identifier
module HasPuid
  extend ActiveSupport::Concern

  included do
    before_validation :generate_puid, on: :create
  end

  class_methods do
    def model_prefix
      raise NotImplementedError
    end
  end

  def generate_puid
    self.puid = Irida::PersistentUniqueId.generate(self)
  end
end
