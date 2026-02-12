# frozen_string_literal: true

# Temporary workaround for Ruby 3.4 + Coverage(eval: true) segfaults when
# class_eval is called with a negative line number.
# Ruby bug: https://bugs.ruby-lang.org/issues/19363
# Related ViewComponent changes: https://github.com/ViewComponent/view_component/pull/2541
module IridaNext
  # Overrides ViewComponent template compilation to avoid negative eval line
  # numbers while coverage is running.
  module ViewComponentCoveragePatch
    def compile_to_component
      @component.silence_redefinition_of_method(call_method_name)

      safe_lineno = coverage_running? && @lineno.to_i.negative? ? 1 : @lineno

      # rubocop:disable Style/EvalWithLocation, Style/DocumentDynamicEvalDefinition
      @component.class_eval <<~RUBY, @path, safe_lineno
        def #{call_method_name}
          #{compiled_source}
        end
      RUBY
      # rubocop:enable Style/EvalWithLocation, Style/DocumentDynamicEvalDefinition

      @component.define_method(safe_method_name, @component.instance_method(@call_method_name))
    end
  end

  # Installs the ViewComponent coverage patch once template compilation code is loaded.
  module ViewComponentCoveragePatchInstaller
    def self.install!
      require 'view_component/template' if defined?(ViewComponent) && !defined?(ViewComponent::Template)
      return unless defined?(ViewComponent::Template)
      return if ViewComponent::Template < IridaNext::ViewComponentCoveragePatch

      ViewComponent::Template.prepend(IridaNext::ViewComponentCoveragePatch)
    end
  end
end

ActiveSupport.on_load(:view_component) do
  IridaNext::ViewComponentCoveragePatchInstaller.install!
end

IridaNext::ViewComponentCoveragePatchInstaller.install!
