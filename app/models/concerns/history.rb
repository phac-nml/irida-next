# frozen_string_literal: true

# Concern for models that need log data
module History
  extend ActiveSupport::Concern

  def log_data_without_changes
    log_data = []
    reload_log_data.data['h'].each do |change_log|
      responsible = User.find(change_log['m']['_r']).email
      log_data << { version: change_log['v'], user: responsible, updated_at: change_log['c']['updated_at'] }
    end
    log_data
  end

  def log_data_with_changes(version) # rubocop:disable Metrics/AbcSize
    log_data = reload_log_data.data['h']
    initial_version = log_data.detect { |h| h['v'] == 1 }
    current_version = log_data.detect { |h| h['v'] == version.to_i }
    versions_after_initial = log_data.reject { |h| h['v'] == version.to_i }

    versions_after_initial.each do |ver|
      initial_version['c'].merge!(ver['c'])
    end

    responsible = User.find(current_version['m']['_r']).email

    { version: version.to_i, user: responsible,
      changes_from_prev_version: current_version['c'],
      previous_version: initial_version['c'] }
  end
end
