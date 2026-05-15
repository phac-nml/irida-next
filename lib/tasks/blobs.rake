# frozen_string_literal: true

namespace :blobs do
  desc 'destroys all unattached blobs older than :days_old, Default = 1'
  task :cleanup, [:days_old] => [:environment] do |_t, args|
    args.with_defaults(days_old: 1)
    puts "Running unattached blob cleanup job for files deleted more than '#{args.days_old}' day ago."
    UnattachedBlobsCleanupJob.perform_now(args.days_old.to_i)
  end
end
