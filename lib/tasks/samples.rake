# frozen_string_literal: true

namespace :samples do
  desc 'destroys all samples older than :days_old, Default = 7'
  task :cleanup, [:days_old] => [:environment] do |_t, args|
    args.with_defaults(days_old: 7)
    puts "Running sample cleanup job for samples deleted more than '#{args.days_old}' day ago."
    SamplesCleanupJob.perform_now(days_old: args.days_old.to_i)
  end
end
