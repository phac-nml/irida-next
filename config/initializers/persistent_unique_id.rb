# frozen_string_literal: true

require 'irida/persistent_unique_id'

Irida::PersistentUniqueId.app_prefix = (ENV['PUID_APP_PREFIX'] || 'INXT')
