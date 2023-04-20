# frozen_string_literal: true

class Component < ViewComponent::Base
  attr_reader :system_arguments

  include ViewHelper
  include ClassNameHelper
end
