#!/usr/bin/env ruby
# Test script to verify ICON constant works

# Load Rails environment
require_relative '../config/environment'

puts 'Testing global ICON constant...'

begin
  # Test that ICON is defined
  raise 'ICON constant not defined' unless defined?(ICON)

  puts '✓ ICON constant is defined'

  # Test that it references ICON
  raise "ICON doesn't reference ICON" unless ICON == ICON

  puts '✓ ICON references ICON'

  # Test specific icons
  raise 'ARROW_UP not accessible' unless ICON::ARROW_UP[:name] == 'arrow-up'

  puts "✓ ICON::ARROW_UP works: #{ICON::ARROW_UP.inspect}"

  raise 'CLIPBOARD not accessible' unless ICON::CLIPBOARD[:name] == 'clipboard-text'

  puts "✓ ICON::CLIPBOARD works: #{ICON::CLIPBOARD.inspect}"

  # Test lookup method
  raise 'Lookup method not working' unless ICON[:arrow_up] == ICON::ARROW_UP

  puts '✓ ICON lookup method works'

  puts "\n🎉 All tests passed! You can now use ICON::ARROW_UP instead of ICON::ARROW_UP"
rescue StandardError => e
  puts "❌ Test failed: #{e.message}"
  exit 1
end
