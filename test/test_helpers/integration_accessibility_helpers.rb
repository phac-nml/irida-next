# frozen_string_literal: true

require 'open3'

module IntegrationAccessibilityHelpers
  AXE_RUN_TAGS = %w[wcag2a wcag2aa wcag21a wcag22a wcag21aa wcag22aa best-practice].freeze

  AXE_SCRIPT = <<~JAVASCRIPT.freeze
    import { JSDOM } from 'jsdom';

    const html = await new Promise((resolve) => {
      let input = '';
      process.stdin.setEncoding('utf8');
      process.stdin.on('data', (chunk) => { input += chunk; });
      process.stdin.on('end', () => resolve(input));
    });
    const dom = new JSDOM(html, { url: 'http://www.example.com' });
    global.window = dom.window;
    global.document = dom.window.document;
    global.Node = dom.window.Node;
    global.Element = dom.window.Element;

    const { default: axe } = await import('axe-core');
    const results = await axe.run(dom.window.document, {
      runOnly: { type: 'tag', values: #{AXE_RUN_TAGS.to_json} }
    });
    process.stdout.write(JSON.stringify(results.violations));
  JAVASCRIPT

  def assert_response_accessible
    output, error, status = Open3.capture3(
      'node',
      '--input-type=module',
      '--eval',
      AXE_SCRIPT,
      stdin_data: response.body,
      chdir: Rails.root.to_s
    )

    assert status.success?, "axe-core accessibility audit failed: #{error}"

    violations = JSON.parse(output)
    assert_empty violations, <<~MESSAGE
      Expected no axe violations, found #{violations.count}
      #{violations.map { |violation| "#{violation['id']}: #{violation['help']}" }.join("\n")}
    MESSAGE
  end
end
