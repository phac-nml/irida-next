# frozen_string_literal: true

namespace :assets do
  desc 'Build JavaScript and CSS assets using esbuild'
  task build: :environment do
    puts 'Building assets with esbuild...'

    # Ensure the builds directory exists
    builds_dir = Rails.root.join('app/assets/builds')
    FileUtils.mkdir_p(builds_dir) unless Dir.exist?(builds_dir)

    # Run pnpm build
    system('pnpm run build') || abort('Asset build failed!')

    puts 'Assets built successfully'
  end
end

# Hook into Rails test:prepare to build assets before tests
Rake::Task['test:prepare'].enhance(['assets:build']) if Rake::Task.task_defined?('test:prepare')
