# frozen_string_literal: true

module HTML5Helpers
  def assert_html5_inputs_valid(expected_result: true) # rubocop:disable Metrics/MethodLength
    results = page.driver.evaluate_async_script <<~JS
      const callback = arguments[arguments.length - 1];
      const inputs = document.querySelectorAll("[required]");

      let mismatched_patterns = [];
      for (const input of inputs) {
        input_label = input.labels[0].innerText
        if(input.validity['patternMismatch'] == true) {
          mismatched_patterns.push(input_label);
        }
      }
      callback(mismatched_patterns);
    JS

    if expected_result
      assert results.empty?
    else
      message =
        "The values supplied for the following inputs failed their respective pattern HTML5 validations:\n\n\t#{results.join("\n")}" # rubocop:disable Layout/LineLength
      assert_not results.empty?, message
    end
  end
end
