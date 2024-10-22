# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flowbite/view_components/version'

Gem::Specification.new do |spec|
  spec.name          = 'flowbite_view_components'
  spec.authors       = ['Bioinformatics and Computational Biology Unit, Public Health Agency of Canada']
  spec.email         = ['bioinformatics@phac-aspc.gc.ca']
  spec.version       = Flowbite::ViewComponents::Version::STRING
  spec.summary       = 'Flowbite View Components'
  spec.license       = 'MIT'
  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']
  spec.required_ruby_version = Gem::Requirement.new('>= 3.2.0')
  spec.add_dependency 'actionview', '>= 5.0.0'
  spec.add_dependency 'activesupport', '>= 5.0.0'
  spec.add_dependency 'heroicon-rails', '>= 0.2.9'
  spec.add_dependency 'view_component', ['>= 3.1', '< 4.0']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
