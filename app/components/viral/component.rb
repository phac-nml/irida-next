# frozen_string_literal: true

module Viral
  # Base component structure for Viral Components
  class Component < ViewComponent::Base
    attr_reader :system_arguments

    include ClassNameHelper
    include ViewHelper
    include Pathogen::Helpers
  end
end
