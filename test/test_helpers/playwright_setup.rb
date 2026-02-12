# frozen_string_literal: true

require 'capybara-playwright-driver'

module Capybara
  module Playwright
    class Node
      class FileUpload < Settable
        def set(value, **_options)
          file =
            if value.is_a?(File)
              value.path
            elsif value.is_a?(Enumerable)
              value.map(&:to_s)
            elsif value.nil?
              []
            else
              value.to_s
            end
          @element.set_input_files(file, timeout: @timeout)
        end
      end
    end
  end
end

Capybara.register_driver(:irida_next_playwright) do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: ENV['PLAYWRIGHT_BROWSER']&.to_sym || :chromium,
    headless: !ENV['HEADLESS'].in?(%w[n 0 no false]),
    viewport: { width: 1280, height: 1024 },
    playwright_cli_executable_path: 'pnpm exec playwright',
    timeout: 45
  )
end

# Configure Capybara to use :irida_next_playwright driver by default
Capybara.default_driver = Capybara.javascript_driver = :irida_next_playwright
