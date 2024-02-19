# frozen_string_literal: true

module TurboStreams
  # Helper for Session Storage
  module SessionStorageHelper
    def update_session_storage_item(storage_key, storage_value)
      turbo_stream_action_tag :update_session_storage_item, storage_key:, storage_value:
    end
  end
end
Turbo::Streams::TagBuilder.prepend(TurboStreams::SessionStorageHelper)
