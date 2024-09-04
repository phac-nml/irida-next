# frozen_string_literal: true

ActiveSupport.on_load(:active_storage_blob) do
  def self.ransackable_attributes(_auth_object = nil)
    %w[filename byte_size]
  end
end
