# frozen_string_literal: true

# Capybara settings (not covered by Rails system tests)

Capybara.server = :puma, { Silent: true }

# Make server listening on all hosts
Capybara.server_host = '0.0.0.0'
# Use a hostname accessible from the outside world
Capybara.app_host = 'http://localhost'

# Which domain to use when setting cookies directly in tests.
CAPYBARA_COOKIE_DOMAIN = URI.parse(Capybara.app_host).host.then do |host|
  # If host is a top-level domain
  next host unless host.include?('.')

  ".#{host}"
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
