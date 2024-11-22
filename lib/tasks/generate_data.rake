# frozen_string_literal: true

require 'faker'

desc 'creates a lot of samples on project and group'
task generate_benchmark_samples: [:environment] do |_t, _args|
  puts 'Creating samples'

  user = User.first # admin

  # Make some projects with varying sizes
  # project_sizes = [1, 20, 300] # small set
  project_sizes = [1000, 20_000] # large set
  # project_sizes = [1000, 20_000, 500_000] # large set
  project_sizes.each do |sample_count|
    puts "starting creation of project with sample size of #{sample_count}"
    generate_project_data(user, "METADATAV2_project_size#{sample_count}", sample_count, user.namespace)
  end

  # Make some groups with varying sizes of projects
  # These align with sizes in single projects
  # group_sizes_project_count_sample_count = [ # small set
  #   { project_count: 1, sample_count: 10 },
  #   { project_count: 2, sample_count: 100 },
  #   { project_count: 10, sample_count: 50 }
  # ]
  group_sizes_project_count_sample_count = [ # large set
    { project_count: 10, sample_count: 100 },
    { project_count: 20, sample_count: 1000 }#,
    # { project_count: 100, sample_count: 5000 }
  ]
  group_sizes_project_count_sample_count.each do |project_count_sample_count_pair|
    project_count = project_count_sample_count_pair[:project_count]
    sample_count = project_count_sample_count_pair[:sample_count]
    puts "starting creation of group with #{project_count} projects, each with #{sample_count} samples"
    generate_group_data(
      user,
      "METADATAV2_group_proj_count-#{project_count}_samp_count-#{sample_count}",
      project_count,
      'METADATAV2_grp_proj',
      sample_count
    )
  end
end

def generate_group_data(user, group_name, project_count, project_name_base, samples_per_project_count)
  # make a group
  target_group = create_group(user, group_name, group_name, "#{group_name}desc")
  puts "target group: #{target_group.full_name}"
  puts "persisted? #{target_group.persisted?}"

  unless target_group.persisted?
    errors = target_group.errors.map do |error|
      { path: ['group', error.attribute.to_s.camelize(:lower)], message: error.message }
    end
    puts errors
  end

  (1..project_count).each do |index|
    generate_project_data(user, "#{project_name_base}_n_#{index}", samples_per_project_count, target_group)
  end
end

def generate_project_data(user, project_name, sample_count, parent_namespace)
  # populate a project
  target_project = create_project(user, project_name, project_name, "#{project_name}desc", parent_namespace)
  puts "target project: #{target_project.full_name}"
  puts "persisted? #{target_project.persisted?}"

  unless target_project.persisted?
    errors = target_project.errors.map do |error|
      { path: ['project', error.attribute.to_s.camelize(:lower)], message: error.message }
    end
    puts errors
  end

  gen_samples(user, target_project, sample_count, "gen_samp_on_#{project_name}")
end

def create_project(user, name, path, description, parent_namespace)
  namespace_attributes = { name:, path:, description:, parent_id: parent_namespace.id }
  Projects::CreateService.new(
    user, { namespace_attributes: }
  ).execute
end

def create_group(user, name, path, description)
  params = { name:, path:, description: }
  Groups::CreateService.new(user, params).execute
end

def gen_samples(user, target_obj, count, base_name)
  (1..count).each do |index|
    sample_full_name = "#{base_name}_n_#{index}"
    sample = Samples::CreateService.new(
      user, target_obj, {
        name: sample_full_name,
        description: "#{sample_full_name}_desc"
      }
    ).execute
    gen_metadata(sample.project, sample, user)
    print_and_flush '.'
  end
end

def gen_metadata(project, sample, user)
  Samples::Metadata::UpdateService.new(project, sample, user, { 'metadata' => fake_metadata }).execute
end

def fake_metadata # rubocop:disable Metrics/MethodLength
  indsc_abbr = %w[SRR ERR DRR]
  random_abbr = indsc_abbr.sample
  random_date = Faker::Date.between(from: 2.years.ago, to: Time.zone.today)

  {
    'WGS_id' => Faker::Number.number(digits: 10),
    'NCBI_ACCESSION' => "NM_#{Faker::Number.decimal(l_digits: 7, r_digits: 1)}",
    'country' => Faker::Address.country,
    'food' => Faker::Food.dish,
    'gender' => Faker::Gender.binary_type,
    'age' => Faker::Number.between(from: 1, to: 100),
    'onset' => random_date,
    'earliest_date' => random_date,
    'patient_sex' => Faker::Gender.binary_type,
    'patient_age' => Faker::Number.between(from: 1, to: 100),
    'insdc_accession' => "#{random_abbr}#{Faker::Number.number(digits: 8)}"
  }
end

def print_and_flush(str)
  print str
  $stdout.flush
end
