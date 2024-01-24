# frozen_string_literal: true

Logidze::Model.module_eval do
  # Loads log_data field from the database (with deleted objects), stores to the attributes hash and returns it
  def reload_log_data
    self.log_data = self.class.with_deleted.where(self.class.primary_key => id)
                        .pluck("#{self.class.table_name}.log_data".to_sym) # rubocop:disable Rails/Pick
                        .first
  end
end
