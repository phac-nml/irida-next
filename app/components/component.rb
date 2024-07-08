# frozen_string_literal: true

# Component class
class Component < ViewComponent::Base
  attr_reader :system_arguments

  include ViewHelper
  include ClassNameHelper
end
