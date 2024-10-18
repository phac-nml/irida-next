# frozen_string_literal: true

module Flowbite
  # @private
  # :nocov:
  class Component < ViewComponent::Base
    erb_template <<-ERB
      <div class="bg-red-500">
        <%= content %>
      </div>
    ERB
  end
end
