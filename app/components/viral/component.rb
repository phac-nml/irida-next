# frozen_string_literal: true

module Viral
  class Component < ViewComponent::Base
    attr_reader :system_arguments

    include ClassNameHelper
    include ViewHelper
  end
end
