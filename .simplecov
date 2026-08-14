SimpleCov.load_profile 'rails'
SimpleCov.group 'Graphql', 'app/graphql'
SimpleCov.group 'View Components', 'app/components'
SimpleCov.group 'Policies', 'app/policies'
SimpleCov.enable_coverage :method
SimpleCov.enable_coverage :branch
SimpleCov.enable_coverage :eval
