# frozen_string_literal: true

namespace :javascript do
  desc 'Build JavaScript bundles with esbuild'
  task build: :environment do
    sh 'pnpm run build:js'
  end
end

Rake::Task['assets:precompile'].enhance(['javascript:build'])
