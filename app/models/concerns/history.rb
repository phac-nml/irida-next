# frozen_string_literal: true

# Concern for models that need log data
module History
  extend ActiveSupport::Concern

  def log_data_without_changes
    log_data = []

    reload_log_data.data['h'].each do |change_log|
      version = change_log['v'].to_i
      responsible = responsible_user_for_version(change_log)

      log_data << { version: change_log['v'], user: responsible,
                    updated_at: DateTime.parse(Time.zone.at(0, change_log['ts'], :millisecond).to_s),
                    restored: record_restored?(change_log, version),
                    deleted: record_deleted?(change_log, version),
                    transferred: record_transferred?(change_log, version) }
    end
    log_data
  end

  def log_data_with_changes(version)
    version = version.to_i

    log_data = reload_log_data.data['h']
    initial_version = log_data.detect { |h| h['v'] == 1 }

    # version requested
    current_version = log_data.detect { |h| h['v'] == version }

    initial_version = merge_changes_to_initial_version(log_data, initial_version, version)

    responsible = responsible_user_for_version(current_version)

    { version:, user: responsible,
      changes_from_prev_version: format_changes(current_version),
      previous_version: format_changes(initial_version) }
  end

  private

  # Since versions > version 1 only track the changes made in each version we
  # merge the changes into the initial version which will be used
  # to display the differences between the previous version and the
  # current version
  def merge_changes_to_initial_version(log_data, initial_version, version)
    versions_after_initial = log_data.reject { |h| h['v'] == 1 || h['v'] >= version }

    # Loop through the versions after the initial one and
    # merge the changes to the initial_version
    versions_after_initial.each do |ver|
      initial_version['c'].merge!(ver['c'])
    end

    initial_version
  end

  # If the version doesn't have metadata for the responsible user
  # we set the user to `System` otherwise the user's email
  def responsible_user_for_version(current_version)
    # Change was made outside the web request (ie. rails console)
    unless current_version.key?('m') && current_version['m'].key?('_r')
      return I18n.t('activerecord.concerns.history.system')
    end

    User.find(current_version['m']['_r']).email
  end

  # Format keys in changes to format required and remove
  # any keys that don't need to be displayed to user
  def format_changes(changes)
    changes = changes['c']

    datetime_format = I18n.t('time.formats.default')

    if changes.key?('deleted_at') && !changes['deleted_at'].nil?
      changes['deleted_at'] =
        DateTime.parse(changes['deleted_at']).strftime(datetime_format)
    end
    changes.except('id')
  end

  def record_deleted?(change_log, version)
    return false if version == 1
    return false unless change_log['c'].key?('deleted_at')

    change_log['c'].key?('deleted_at') && change_log['c']['deleted_at'].present?
  end

  def record_restored?(change_log, version)
    return false if version == 1

    change_log['c'].key?('deleted_at') && change_log['c']['deleted_at'].blank?
  end

  def record_transferred?(change_log, version)
    return false if version == 1

    change_log['c'].key?('parent_id') || change_log['c'].key?('project_id')
  end
end
