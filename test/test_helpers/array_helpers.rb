# frozen_string_literal: true

module ArrayHelpers
  def assert_same_unique_elements(array1 = [], array2 = [])
    assert array1.allbits?(array2)
  end
end
