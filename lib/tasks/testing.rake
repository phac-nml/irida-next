# frozen_string_literal: true

require 'minitest'
require 'rails/test_unit/runner'

namespace :test do
  task :components do # rubocop:disable Rails/RakeEnvironment
    Rails::TestUnit::Runner.run_from_rake('test', 'test/components')
  end
end
