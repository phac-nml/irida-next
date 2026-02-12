# frozen_string_literal: true

module AxeHelpers
  # Ruby class to wrap the JSON results payload
  class AxeResults
    Violation = Data.define(:id, :impact, :tags, :description, :help, :helpUrl) # rubocop:disable Naming/MethodName

    AXE_JS = <<~JS.freeze
      #{Rails.root.join('node_modules/axe-core/axe.js').read}

      axe.run().then(results => console.log(JSON.stringify(results)));
    JS

    def initialize(page)
      unless page.driver.is_a?(Capybara::Playwright::Driver)
        raise ArgumentError,
              'make sure to use the playwright driver with this matcher'
      end

      @page = page
    end

    def violations
      @violations ||=
        axe_results
        .fetch('violations')
        .map do |json|
          # omitting nodes because it clutters up the output
          Violation.new(**json.except('nodes'))
        end
    end

    private

    attr_reader :page

    # inject the axe JS into the page, wait for the results to be logged, parse the results, and return them
    def axe_results
      @axe_results ||=
        begin
          axe_results_console_message =
            page.driver.with_playwright_page do |playwright_page|
              playwright_page.expect_console_message(
                predicate: method(:console_message_contains_axe_results?)
              ) { playwright_page.add_script_tag(content: AXE_JS) }
            end
          JSON.parse(axe_results_console_message.text)
        end
    end

    # predicate method which identifies the console log that contains the axe results payload
    def console_message_contains_axe_results?(msg)
      JSON.parse(msg.text).dig('testRunner', 'name') == 'axe'
    rescue StandardError
      false
    end
  end

  def assert_accessible
    actual = AxeResults.new(page)

    assert actual.violations.empty?, <<~MSG
      Expected no axe violations, found #{actual.violations.count}
      #{actual.violations.join("\n\n")}
    MSG
  end

  # Capybara Overrides to run accessibility checks when UI changes.
  def fill_in(locator = nil, **kwargs)
    super

    assert_accessible
    w3c_validate content: html
  end

  def visit(path, **attributes)
    super

    assert_accessible
    w3c_validate content: html
  end
end
