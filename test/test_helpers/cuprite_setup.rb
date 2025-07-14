# frozen_string_literal: true

require 'capybara/cuprite'

# Then, we need to register our driver to be able to use it later
# with #driven_by method.
Capybara.register_driver(:irida_next_cuprite) do |app|
  browser_options = {}
  browser_options['no-sandbox'] = nil if ENV['CI'] || ENV.key?('BROWSERLESS_HOST')
  browser_options['disable-smooth-scrolling'] = true

  remote_options = {}
  if ENV.key?('BROWSERLESS_HOST')
    launch_args = { defaultViewport: { height: 1400, width: 1400 },
                    args: ["--unsafely-treat-insecure-origin-as-secure=http://rails-app:#{Capybara.server_port}"],
                    env: {
                      TZ: Time.zone.name
                    } }.to_json
    remote_options[:ws_url] =
      "ws://#{ENV.fetch('BROWSERLESS_HOST', nil)}:3333?launch=#{launch_args}"
  end

  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1400, 1400],
    # See additional options for Dockerized environment in the respective section of this article
    browser_options: browser_options,
    # Increase Chrome startup wait time (required for stable CI builds)
    process_timeout: 60,
    # Page load timeout, default is 5
    timeout: 45,
    # Enable debugging capabilities
    inspector: ENV.fetch('INSPECTOR', false),
    # Allow running Chrome in a headful mode by setting HEADLESS env
    # var to a falsey value
    headless: !ENV['HEADLESS'].in?(%w[n 0 no false]),
    **remote_options
  )
end

# Configure Capybara to use :cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :irida_next_cuprite
