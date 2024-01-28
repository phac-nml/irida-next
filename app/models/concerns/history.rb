# frozen_string_literal: true

# Concern for models that need log data
module History
  extend ActiveSupport::Concern

  def log_data_without_changes
    log_data = []
    reload_log_data.data['h'].each do |change_log|
      responsible = responsible_user_for_version(change_log)
      log_data << { version: change_log['v'], user: responsible,
                    updated_at: DateTime.parse(change_log['c']['updated_at']).strftime('%a %b %e %Y %H:%M') }
    end
    log_data
  end

  def log_data_with_changes(version) # rubocop:disable Metrics/AbcSize
    version = version.to_i
    log_data = reload_log_data.data['h']
    initial_version = log_data.detect { |h| h['v'] == 1 }
    # version requested
    current_version = log_data.detect { |h| h['v'] == version }
    versions_after_initial = log_data.reject { |h| h['v'] == 1 || h['v'] >= version }

    # Loop through the versions after the initial one and
    # merge the changes to the initial_version
    versions_after_initial.each do |ver|
      initial_version['c'].merge!(ver['c'])
    end

    responsible = responsible_user_for_version(current_version)

    { version:, user: responsible,
      changes_from_prev_version: format_changes(current_version['c']),
      previous_version: format_changes(initial_version['c']) }
  end

  def responsible_user_for_version(current_version)
    # Change was made outside the web request (ie. rails console)
    unless current_version.key?('m') && current_version['m'].key?('_r')
      return I18n.t('activerecord.concerns.history.system')
    end

    User.find(current_version['m']['_r']).email
  end

  # Format keys in changes to format required
  # Currently converts string to date time and formats to YYYY-MM-DD H:M
  # for created_at, deleted_at, and updated_at
  def format_changes(changes)
    datetime_format = I18n.t('time.formats.default')

    if changes.key?('created_at')
      changes['created_at'] =
        DateTime.parse(changes['created_at']).strftime(datetime_format)
    end

    if changes.key?('deleted_at') && !changes['deleted_at'].nil?
      changes['deleted_at'] =
        DateTime.parse(changes['deleted_at']).strftime(datetime_format)
    end

    if changes.key?('updated_at')
      changes['updated_at'] =
        DateTime.parse(changes['updated_at']).strftime(datetime_format)
    end
    changes
  end
end
