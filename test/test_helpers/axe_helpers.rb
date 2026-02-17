# frozen_string_literal: true

module AxeHelpers
  # Ruby class to wrap the JSON results payload
  class AxeResults
    Violation = Data.define(:id, :impact, :tags, :description, :help, :help_url)
    ExclusionRule = Data.define(:id, :selector)

    AXE_COMMAND = <<~COMMAND
      axe.run({ runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'] }, elementRef: true })
    COMMAND

    AXE_JS = <<~JS.freeze
      #{Rails.root.join('node_modules/axe-core/axe.js').read}

      #{AXE_COMMAND}.then(results => console.log(JSON.stringify({ testRunner: results.testRunner, violations: results.violations })));
    JS

    def initialize(page, exclusions: [])
      unless page.driver.is_a?(Capybara::Playwright::Driver)
        raise ArgumentError,
              'make sure to use the playwright driver with this matcher'
      end

      @page = page
      @exclusions = exclusions
    end

    def violations
      @violations ||=
        remove_exclusions(axe_results.fetch('violations')).map do |json|
          Violation.new(
            id: json['id'],
            impact: json['impact'],
            tags: json['tags'],
            description: json['description'],
            help: json['help'],
            help_url: json['helpUrl']
          )
        end
    end

    private

    attr_reader :page

    # Remove any exclusions from the results
    def remove_exclusions(json)
      json.reject do |item|
        @exclusions.any? do |exclusion|
          exclusion.id == item['id'] && item['nodes'].any? do |node|
            html_matches_selector?(node['html'], exclusion.selector)
          end
        end
      end
    end

    def html_matches_selector?(html, selector)
      Nokogiri::HTML.parse(html).css(selector).any?
    end

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
    exclusions = if page.current_url.match?(%r{/rails/lookbook})
                   ['page-has-heading-one']
                 else
                   []
                 end
    actual = AxeResults.new(page, exclusions: exclusions)

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
