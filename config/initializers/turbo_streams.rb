# frozen_string_literal: true

Turbo::Streams::BroadcastJob.queue_name = 'transactional_messages'
Turbo::Streams::ActionBroadcastJob.queue_name = 'transactional_messages'
Turbo::Streams::BroadcastStreamJob.queue_name = 'transactional_messages'
