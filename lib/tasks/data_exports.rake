# frozen_string_literal: true

namespace :data_exports do
  desc 'destroys expired data exports'
  task cleanup: [:environment] do |_t, _args|
    puts 'Running data exports cleanup job for expired exports.'
    DataExports::CleanupJob.perform_now
  end
end
