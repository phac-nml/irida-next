# frozen_string_literal: true

module AxeHelpers
  AccessibilityError = Class.new(StandardError)

  AXE_RULES_TO_SKIP = %i[].freeze

  def format_accessibility_errors(violations) # rubocop:disable Metrics
    index = 0
    results = violations.map do |summary|
      summary['nodes'].map do |node|
        index += 1
        %{
    #{index}) #{summary['id']}: #{summary['description']} (#{summary['impact']})
    #{summary['helpUrl']}
    The following #{node['any'].size} node violate this rule:
      #{node['any'].map do |_violation|
        items = node['failureSummary'].sub('Fix any of the following:', '').split("\n")
        %(Selector: #{node['target'].join(', ')}
      HTML: #{node['html']}
      Fix any of the following:
      #{items.map { |item| "- #{item.strip}" }.join}
    )
      end.join}
            }
      end.join
    end.join
    %(
    Found #{violations.size} accessibility violations:
    #{results}
      )
  end

  def assert_accessible(excludes: [], max_retry_attempts: 2) # rubocop:disable Metrics
    excludes = Set.new(AXE_RULES_TO_SKIP) + excludes

    axe_exists = page.driver.evaluate_async_script <<~JS
      const callback = arguments[arguments.length - 1];
      callback(!!window.axe)
    JS

    retry_attempts = 0

    begin
      results = page.driver.evaluate_async_script <<~JS
        const callback = arguments[arguments.length - 1];
        #{File.read('node_modules/axe-core/axe.min.js') unless axe_exists}
        // Remove cyclic references
        // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Errors/Cyclic_object_value#examples
        const getCircularReplacer = () => {
          const seen = new WeakSet();
          return (key, value) => {
            if (typeof value === "object" && value !== null) {
              if (seen.has(value)) {
                return;
              }
              seen.add(value);
            }
            return value;
          };
        };
        const excludedRulesConfig = {};
        for (const rule of [#{excludes.map { |id| "'#{id}'" }.join(', ')}]) {
          excludedRulesConfig[rule] = { enabled: false };
        }
        const options = {
          elementRef: true,
          resultTypes: ['violations'],
          rules: {
            ...excludedRulesConfig
          }
        }
        axe.run(document.body, options).then(res => JSON.parse(JSON.stringify(res, getCircularReplacer()))).then(callback);
      JS

      violations = results['violations']

      raise AccessibilityError, 'Not accessible' unless violations.empty?
    rescue AccessibilityError
      retry_attempts += 1
      page.driver.wait_for_network_idle
      retry if retry_attempts < max_retry_attempts
    end

    message = format_accessibility_errors(violations)

    assert violations.empty?, message
  end

  # Capybara Overrides to run accessibility checks when UI changes.
  def fill_in(locator = nil, **kwargs)
    super

    assert_accessible
  end

  def visit(path, **attributes)
    super

    assert_accessible
  end
end
