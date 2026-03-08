# Testing Patterns

**Analysis Date:** 2026-03-08

## Test Framework

**Runner:**

- Minitest ~> 5.27
- Config: `test/test_helper.rb` (main), `test/application_system_test_case.rb` (system tests)

**Supporting Libraries:**

- `simplecov` — code coverage (branch coverage enabled)
- `mocha` — stubbing/mocking (`require: false`, opt-in per file)
- `capybara` — system test DSL
- `capybara-playwright-driver` — Playwright-backed browser automation (Chromium)
- `webmock` — HTTP request stubbing for external API calls
- `timecop` — time manipulation
- `w3c_validators` — HTML5 markup validation
- `minitest-retry` — auto-retry flaky tests (`Minitest::Retry.use!`)
- `faker` — fake data (development group only, not test group)

**Run Commands:**

```bash
bin/rails test:all          # Run all tests (unit + system)
bin/rails test              # Run unit tests only
HEADLESS=false bin/rails test:system  # System tests with browser window visible
open coverage/index.html    # View SimpleCov HTML report
```

## Test File Organization

**Location:**

- Unit tests: `test/` directory mirroring `app/` structure
- System tests: `test/system/`
- Component unit tests: `test/components/`
- Fixtures: `test/fixtures/` (YAML files)
- Test helpers: `test/test_helpers/`

**Naming:**

- Unit tests: `{ClassName}Test` → file `test/{layer}/{name}_test.rb`
- System tests: `{Feature}Test < ApplicationSystemTestCase`
- GraphQL tests: `test/graphql/{mutation_or_query}_test.rb`
- ViewComponent tests: `{ComponentName}Test < ViewComponentTestCase`

**Structure:**

```
test/
├── test_helper.rb              # Global setup, SimpleCov, parallel config
├── application_system_test_case.rb  # Playwright driver, Warden helpers
├── view_component_test_case.rb      # ViewComponent base with markup validation
├── fixtures/                   # YAML fixture files (users, groups, projects, samples...)
├── test_helpers/               # Shared helper modules
│   ├── axe_helpers.rb          # assert_accessible (WCAG 2.0/2.1 A/AA)
│   ├── capybara_setup.rb       # Capybara configuration
│   ├── playwright_setup.rb     # Playwright driver registration
│   ├── system_test_ui_helper.rb
│   ├── w3c_validation_helpers.rb
│   └── ...
├── models/                     # ActiveRecord model tests
├── controllers/                # ActionDispatch integration tests
├── system/                     # Capybara+Playwright end-to-end tests
├── components/                 # ViewComponent unit tests
│   └── previews/               # Lookbook component previews
├── graphql/                    # GraphQL mutation/query tests
├── services/                   # Service object tests
├── policies/                   # ActionPolicy tests
└── jobs/                       # ActiveJob tests
```

## Test Structure

**Base Test Classes:**

| Test Type                                 | Base Class                        | Where                                  |
| ----------------------------------------- | --------------------------------- | -------------------------------------- |
| Models, Services, Jobs, Policies, GraphQL | `ActiveSupport::TestCase`         | `test/test_helper.rb`                  |
| Controllers                               | `ActionDispatch::IntegrationTest` | `test/test_helper.rb`                  |
| System (browser)                          | `ApplicationSystemTestCase`       | `test/application_system_test_case.rb` |
| ViewComponents                            | `ViewComponentTestCase`           | `test/view_component_test_case.rb`     |

**Suite Organization:**

```ruby
# frozen_string_literal: true

require 'test_helper'

class SampleTest < ActiveSupport::TestCase
  def setup
    @sample = samples(:sample1)
    @project = projects(:project1)
  end

  def teardown
    Flipper.disable(:feature_flag_name)
  end

  test 'valid sample' do
    assert @sample.valid?
  end

  test '#destroy removes sample' do
    assert_difference(-> { Sample.count } => -1) do
      @sample.destroy
    end
  end
end
```

**Patterns:**

- `setup` method for fixture loading and instance variable assignment
- `teardown` for Flipper feature flag cleanup and state reset
- `test '...' do` (not `def test_...`) for test definitions
- Test names describe behavior in plain English
- Namespaced service tests wrap in module: `module Samples; class TransferServiceTest < ActiveSupport::TestCase`

## Fixtures

**Format:** YAML with ERB support (`test/fixtures/`)

**Usage:**

```ruby
# In setup:
@user = users(:john_doe)
@sample = samples(:sample1)
@token = personal_access_tokens(:jeff_doe_valid_pat)

# Fixtures use DEFAULTS YAML anchors for shared attributes:
# DEFAULTS: &DEFAULTS
#   encrypted_password: <%= User.new.send :password_digest, "password1" %>
```

**What is fixtured:**

- `users.yml`, `groups.yml`, `projects.yml`, `samples.yml`
- `members.yml`, `namespaces/user_namespaces.yml`, `namespaces/project_namespaces.yml`
- `personal_access_tokens.yml`, `attachments.yml`, `active_storage_blobs.yml`
- `workflow_executions.yml`, `samples_workflow_executions.yml`

All fixtures are loaded for every test via `fixtures :all` in `ActiveSupport::TestCase`.

No factory_bot. All test data uses YAML fixtures only.

## Mocking

**Frameworks:**

- `webmock` — stubs external HTTP requests (used in `test/lib/irida/pipelines*_test.rb`)
- `mocha` — Ruby object stubbing (loaded opt-in with `require 'mocha/minitest'`)
- Method redefinition via `class_eval` for complex behavior stubs

**WebMock pattern:**

```ruby
require 'webmock/minitest'

def setup
  stub_request(:any, 'https://raw.githubusercontent.com/...').to_return(
    body: File.read("#{Rails.root}/test/fixtures/files/...")
  )
end
```

**Method stub pattern (inline):**

```ruby
# Redefine method for duration of block, restore after
original_method = Project.instance_method(:broadcast_refresh_later_to)
Project.class_eval do
  define_method(:broadcast_refresh_later_to) do |streamable, stream_name|
    broadcast_calls << [streamable, stream_name]
    nil
  end
end
yield
ensure
  Project.class_eval { define_method(:broadcast_refresh_later_to, original_method) }
```

**What to mock:**

- External HTTP calls (always via webmock)
- Turbo broadcast methods when testing side-effect counts
- Time-sensitive operations via Timecop

**What NOT to mock:**

- Database interactions (use fixtures + real DB in test env)
- Policy checks (test real authorization via ActionPolicy test helpers)
- Service logic (test services directly, not mocked)

## Authorization Testing

Uses `action_policy` test helper (included globally):

```ruby
# In policy tests:
@policy = SamplePolicy.new(@sample, user: @user)
assert @policy.apply(:destroy_attachment?)

# In service tests, verify authorization by checking error messages:
assert @namespace.errors.full_messages.include?(
  I18n.t('services.samples.transfer.maintainer_transfer_not_allowed')
)
```

## Controller Tests

```ruby
class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:john_doe) }

  test 'should create group' do
    sign_in users(:john_doe)     # Devise helper
    assert_difference('Group.count') do
      post groups_url, params: { group: { name: 'New Group', path: 'new_group' } }
    end
    assert_redirected_to group_url(Group.last)
  end

  test 'unauthorized returns 401' do
    sign_in users(:ryan_doe)
    post groups_path, params: { ... }
    assert_response :unauthorized
  end
end
```

## GraphQL Tests

```ruby
class AttachFilesToSampleTest < ActiveSupport::TestCase
  MUTATION = <<~GRAPHQL
    mutation($files: [String!]!, $sampleId: ID!) {
      attachFilesToSample(input: { files: $files, sampleId: $sampleId }) {
        sample { id }
        status
        errors { path message }
      }
    }
  GRAPHQL

  test 'mutation succeeds with valid token' do
    result = IridaSchema.execute(MUTATION,
                                 context: { current_user: @user, token: @api_scope_token },
                                 variables: { files: [...], sampleId: sample.to_global_id.to_s })
    assert_nil result['errors']
    assert_equal :success, result['data']['attachFilesToSample']['status'][blob.signed_id]
  end
end
```

GraphQL constants (query/mutation strings) defined as Ruby heredoc constants at class level.

## System Tests

```ruby
class GroupsTest < ApplicationSystemTestCase
  def setup
    @user = users(:john_doe)
    login_as @user          # Warden::Test::Helpers
  end

  test 'can create a group' do
    visit groups_url
    click_button I18n.t('general.navbar.new_dropdown.label')
    within %(div[data-controller="slugify"]) do
      fill_in I18n.t('activerecord.attributes.group.name'), with: 'New group'
      click_on I18n.t('groups.create.submit')
    end
    assert_text I18n.t('groups.create.success')
    assert_selector 'h1', text: 'New group'
  end
end
```

**Patterns:**

- `login_as @user` (Warden, not Devise `sign_in`)
- Use `I18n.t(...)` for all text assertions — never hardcode English strings
- `within(css_selector)` to scope interactions
- Playwright driver: Chromium, 1280x1024, 15s default wait, 45s timeout
- Capybara `aria-label` support enabled
- Artifacts saved to `tmp/capybara/`

## ViewComponent Tests

```ruby
require 'view_component_test_case'

class MemberActivityComponentTest < ViewComponentTestCase
  setup do
    @user = users(:john_doe)
    @member = members(:project_one_member_ryan_doe)
  end

  test 'renders member add activity' do
    render_inline Activities::MemberActivityComponent.new(activity: activity_to_render)
    assert_text 'expected text'
    assert_selector 'a', text: @member.user.email
  end
end
```

`ViewComponentTestCase` automatically calls `assert_valid_markup(rendered_content)` after every `render_inline` — HTML5 markup validation is built-in for all component tests.

## Accessibility Testing

System tests and component tests can assert WCAG compliance:

```ruby
assert_accessible   # Runs axe-core against current page (WCAG 2.0/2.1 A/AA tags)
```

Defined in `test/test_helpers/axe_helpers.rb`. Requires Playwright driver.

## Coverage

**Requirements:** No enforced minimum threshold

**Configuration:** `test/test_helper.rb`

- SimpleCov `rails` profile with custom groups
- Groups: `Graphql`, `View Components`, `Policies`
- Branch coverage enabled (`enable_coverage :branch`)
- Filters: `lib/active_storage/service/`, `lib/azure/`, `test/`, `vendor/`

**View Coverage:**

```bash
open coverage/index.html
```

## Test Types

**Unit Tests (`test/models/`, `test/services/`, `test/jobs/`, `test/policies/`):**

- Test single class in isolation using fixtures
- Service tests call `.execute` directly with fixture users/records
- Policy tests instantiate policy object and call `.apply(:method_name?)`

**Controller Integration Tests (`test/controllers/`):**

- `ActionDispatch::IntegrationTest`
- Full HTTP request/response cycle
- Assert response codes and redirects

**GraphQL Tests (`test/graphql/`):**

- `IridaSchema.execute(MUTATION, context:, variables:)` directly
- Assert `result['errors']` nil/present
- Assert `result['data'][...]` structure

**System Tests (`test/system/`):**

- Full browser via Playwright/Capybara
- Test user flows end-to-end
- Login via Warden test helpers

**Component Tests (`test/components/`):**

- ViewComponent unit tests with markup validation
- No browser required

**Parallel Execution:**
Tests run in parallel using `parallelize(workers: :number_of_processors)`. Each worker gets its own ActiveStorage root directory, cleaned up after.

---

_Testing analysis: 2026-03-08_
