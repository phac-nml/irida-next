# frozen_string_literal: true

namespace :workflow_executions do
  desc 'destroys all workflow executions older than :days_old, Default = 7'
  task :cleanup, [:days_old] => [:environment] do |_t, args|
    args.with_defaults(days_old: 7)
    puts "Running workflow execution cleanup job for files deleted more than '#{args.days_old}' day ago."
    WorkflowExecutionsDestroyJob.perform_now(args.days_old.to_i)
  end
end
