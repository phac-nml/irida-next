# frozen_string_literal: true

module ArrayHelpers
  def assert_same_unique_elements(array1 = [], array2 = [])
    (array1 & array2) == array1
  end
end
