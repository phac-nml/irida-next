# frozen_string_literal: true

# Base32 module for converting numerical values to Base32 encoding following rfc3548
module Base32
  module_function

  EncodingError = Class.new(StandardError)

  ALPHABET = [*('A'..'Z'), *('2'..'7')].freeze

  def encode32(number, length)
    return if number.nil? || number.negative? || length.nil? || !length.positive?

    raise EncodingError unless encodable?(number, length)

    encoded = Array.new(length)
    j = encoded.length - 1

    encoded.length.times do |i|
      encoded[j] = ALPHABET[(number >> (5 * i)) & 0x1f]
      j -= 1
    end

    encoded.join
  end

  def decode32(string)
    number = 0

    string.reverse.chars.each_with_index do |char, index|
      number += ALPHABET.index(char) * (32**index)
    end

    number
  end

  def encodable?(number, length)
    Math.log(number + 1, 32) <= length
  end
end
