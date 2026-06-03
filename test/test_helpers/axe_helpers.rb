# frozen_string_literal: true

module AxeHelpers
  # Ruby class to wrap the JSON results payload
  class AxeResults
    Violation = Data.define(:id, :impact, :tags, :description, :help, :help_url, :nodes) do
      def to_s
        [
          "#{id} #{impact}",
          help,
          "Help: #{help_url}",
          'Affected nodes:',
          *nodes.each_with_index.map { |node, index| AxeResults.indent(node.to_s(index + 1), 2) }
        ].join("\n")
      end
    end

    ViolationNode = Data.define(:target, :html, :checks) do
      def to_s(index = nil)
        prefix = index ? "#{index}. " : ''
        lines = ["#{prefix}Target: #{AxeResults.format_target(target)}"]
        lines << "   HTML: #{html}" unless html.to_s.empty?
        checks.each { |check| lines << AxeResults.indent(check.to_s, 3) }
        lines.join("\n")
      end
    end

    Check = Data.define(:message, :data, :related_nodes) do
      def to_s
        lines = ["- #{message}"]
        lines << "  Data: #{AxeResults.format_data(data)}" unless data.nil?
        if related_nodes.any?
          lines << '  Related nodes:'
          related_nodes.each { |node| lines << AxeResults.indent(node.to_s, 4) }
        end
        lines.join("\n")
      end
    end

    RelatedNode = Data.define(:target, :html) do
      def to_s
        [
          "Target: #{AxeResults.format_target(target)}",
          ("HTML: #{html}" unless html.to_s.empty?)
        ].compact.join("\n")
      end
    end
    ExclusionRule = Data.define(:id, :selector)

    # ViewComponent preview pages are not full app layouts (no document h1).
    COMPONENT_PREVIEW_EXCLUSIONS = [
      ExclusionRule.new(id: 'page-has-heading-one', selector: nil)
    ].freeze

    WCAG_AA_RUN_TAGS = %w[wcag2a wcag2aa wcag21a wcag22a wcag21aa wcag22aa best-practice].freeze

    AXE_COMMAND = <<~COMMAND.freeze
      axe.run({ runOnly: { type: 'tag', values: #{WCAG_AA_RUN_TAGS.to_json} } })
    COMMAND

    AXE_JS = <<~JS.freeze
      #{Rails.root.join('node_modules/axe-core/axe.js').read}

      #{AXE_COMMAND}.then(results => console.log(JSON.stringify({ testRunner: results.testRunner, violations: results.violations })));
    JS

    class << self
      def format_target(target)
        case target
        when Array
          if target.first.is_a?(Array)
            target.first.join(' >> ')
          else
            target.join(' > ')
          end
        else
          target.to_s
        end
      end

      def indent(text, spaces)
        padding = ' ' * spaces
        text.lines.map { |line| "#{padding}#{line}" }.join
      end

      def format_data(data)
        case data
        when Hash
          data.map { |key, value| "#{key}=#{format_data(value)}" }.join(', ')
        when Array
          data.map { |value| format_data(value) }.join(', ')
        else
          data.to_s
        end
      end

      def build_violation_node(node_json)
        ViolationNode.new(
          target: node_json['target'],
          html: node_json['html'],
          checks: failure_checks(node_json)
        )
      end

      def failure_checks(node_json)
        %w[any all none].flat_map do |check_type|
          Array(node_json[check_type]).filter_map do |check|
            result = check['result']
            next build_check(check) if result.nil?

            build_check(check) if result != 'passed'
          end
        end.compact.uniq
      end

      def build_check(check_json)
        Check.new(
          message: check_json['message'],
          data: check_json['data'],
          related_nodes: Array(check_json['relatedNodes']).map { |node| build_related_node(node) }
        )
      end

      def build_related_node(node_json)
        RelatedNode.new(target: node_json['target'], html: node_json['html'])
      end
    end

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
            help_url: json['helpUrl'],
            nodes: json['nodes'].map { |node| self.class.build_violation_node(node) }
          )
        end
    end

    private

    attr_reader :page

    # Remove any exclusions from the results
    def remove_exclusions(json)
      json.reject do |item|
        @exclusions.any? { |exclusion| excluded_violation?(item, exclusion) }
      end
    end

    def excluded_violation?(item, exclusion)
      return false unless exclusion.id == item['id']

      exclusion.selector.nil? || item['nodes'].any? do |node|
        html_matches_selector?(node['html'], exclusion.selector)
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

  def assert_accessible(exclusions: nil)
    actual = AxeResults.new(page, exclusions: axe_exclusions(exclusions))

    assert actual.violations.empty?, <<~MSG
      Expected no axe violations, found #{actual.violations.count}
      #{actual.violations.join("\n\n")}
    MSG
  end

  def assert_component_accessible
    assert_accessible(exclusions: AxeResults::COMPONENT_PREVIEW_EXCLUSIONS)
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

  private

  def axe_exclusions(explicit_exclusions)
    return explicit_exclusions unless explicit_exclusions.nil?

    component_preview_page? ? AxeResults::COMPONENT_PREVIEW_EXCLUSIONS : []
  end

  def component_preview_page?
    current_path.include?('rails/view_components')
  end
end
