# frozen_string_literal: true

desc 'destroys all attachments older than :days_old, Default = 7'
task :attachment_cleanup, [:days_old] do |_t, args|
  args.with_defaults(days_old: 7)
  puts "some text #{args.days_old}"
end
