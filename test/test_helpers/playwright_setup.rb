# frozen_string_literal: true

require 'capybara/playwright'

# Then, we need to register our driver to be able to use it later
# with #driven_by method.
Capybara.register_driver(:irida_next_playwright) do |app|
  Capybara::Playwright::Driver.new(
    app,
    playwright_cli_executable_path: 'pnpx playwright',
    browser_type: :chromium,
    window_size: [1400, 1400],
    # Allow running Chrome in a headful mode by setting HEADLESS env
    # var to a falsey value
    headless: !ENV['HEADLESS'].in?(%w[n 0 no false]),
    slowMo: 60
  )
end

# Configure Capybara to use :cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :irida_next_playwright
