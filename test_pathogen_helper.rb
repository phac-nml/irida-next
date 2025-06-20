#!/usr/bin/env ruby
# Test script to verify Pathogen ViewHelper integration

require_relative 'config/environment'

puts 'Testing Pathogen::ViewHelper integration...'

# Check if module is defined
if defined?(Pathogen::ViewHelper)
  puts '✓ Pathogen::ViewHelper module is defined'

  # Check if methods are defined
  methods = Pathogen::ViewHelper.instance_methods.grep(/pathogen/)
  puts "✓ Methods defined: #{methods}"

  # Check if ActionView includes the module
  if ActionView::Base.included_modules.include?(Pathogen::ViewHelper)
    puts '✓ Pathogen::ViewHelper is included in ActionView::Base'
  else
    puts '✗ Pathogen::ViewHelper is NOT included in ActionView::Base'
  end
else
  puts '✗ Pathogen::ViewHelper module is NOT defined'
end

puts 'Done.'
