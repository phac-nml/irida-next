# frozen_string_literal: true

# Capybara settings (not covered by Rails system tests)

Capybara.server = :puma, { Silent: true }

if ENV.key?('BROWSERLESS_HOST')
  Capybara.server_host = '0.0.0.0'
  Capybara.server_port = 43_567
  Capybara.app_host = 'http://rails-app'
end

# Don't wait too long in `have_xyz` matchers
Capybara.default_max_wait_time = 20.seconds

# Normalizes whitespaces when using `has_text?` and similar matchers
Capybara.default_normalize_ws = true

# Allowing search with aria-label
Capybara.enable_aria_label = true

# Where to store artifacts (e.g. screenshots, downloaded files, etc.)
Capybara.save_path = ENV.fetch('CAPYBARA_ARTIFACTS', './tmp/capybara')

Capybara.singleton_class.prepend(Module.new do
  attr_accessor :last_used_session

  def using_session(name, &)
    self.last_used_session = name
    super
  ensure
    self.last_used_session = nil
  end
end)
