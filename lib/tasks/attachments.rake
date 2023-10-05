# frozen_string_literal: true

namespace :attachments do
  desc 'destroys all attachments older than :days_old, Default = 7'
  task :cleanup, [:days_old] => [:environment] do |_t, args|
    args.with_defaults(days_old: 7)
    puts args.days_old
    AttachmentsCleanupJob.perform_now(args.days_old.to_i)
  end
end
