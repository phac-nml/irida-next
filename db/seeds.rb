# frozen_string_literal: true

require 'faker'

Faker::Config.locale = 'en'

return unless Rails.env.development?

@namespace_group_link_expiry_date = (Time.zone.today + 14).strftime('%Y-%m-%d')

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

@illumina_pe_fwd = ActiveStorage::Blob.create_and_upload!(
  io: Rails.root.join('db/files/08-5578-small_S1_L001_R1_001.fastq.gz').open,
  filename: '08-5578-small_S1_L001_R1_001.fastq.gz'
).id

@illumina_pe_rev = ActiveStorage::Blob.create_and_upload!(
  io: Rails.root.join('db/files/08-5578-small_S1_L001_R2_001.fastq.gz').open,
  filename: '08-5578-small_S1_L001_R2_001.fastq.gz'
).id

# Select a reference file
@reference_file = ActiveStorage::Blob.create_and_upload!(
  io: Rails.root.join('db/files/reference/reference.fasta').open,
  filename: 'reference.fasta'
).signed_id

def seed_project(project_params:, creator:, namespace:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  project = Projects::CreateService.new(creator,
                                        {
                                          namespace_attributes: project_params.slice(
                                            :name,
                                            :path,
                                            :description
                                          ).merge({ parent: namespace, owner: creator })
                                        }).execute

  # seed the project members
  if project_params[:member_emails_by_role] # rubocop:disable Style/SafeNavigation
    project_params[:member_emails_by_role].each do |access_level, email|
      seed_members(email, access_level, project.namespace)
    end
  end

  return 0 unless project_params[:sample_count]

  # seed the project samples
  samples_count = seed_samples(project, project_params[:sample_count]) if project_params[:sample_count]
  project.update_columns(samples_count: samples_count) # rubocop:disable Rails/SkipsModelValidations
  project.namespace.update_columns(metadata_summary: fake_metadata_summary(samples_count)) # rubocop:disable Rails/SkipsModelValidations

  # wait at minimum 10 / 12_228.0 seconds to ensure unique puids for samples
  wait_until = project.created_at.to_f + ((samples_count + 10) * 1 / 12_228.0)
  loop do
    sleep(20 / 12_228.0)
    break if Time.now.to_f > wait_until
  end

  samples_count
end

def seed_members(email, access_level, namespace)
  Members::CreateService.new(namespace.owner,
                             namespace,
                             { user: User.find_by(email:),
                               access_level: Member::AccessLevel.access_level_options[access_level.to_s] }).execute
end

def seed_namespace_group_links(user, namespace, group, group_access_level)
  GroupLinks::GroupLinkService.new(user, namespace,
                                   { group_id: group.id,
                                     group_access_level:,
                                     expires_at: @namespace_group_link_expiry_date }).execute
end

def fake_metadata # rubocop:disable Metrics/MethodLength
  indsc_abbr = %w[SRR ERR DRR]
  random_abbr = indsc_abbr.sample
  random_date = Faker::Date.between(from: 2.years.ago, to: Time.zone.today)

  {
    'WGS_id' => Faker::Number.number(digits: 10),
    'ncbi_accession' => "NM_#{Faker::Number.decimal(l_digits: 7, r_digits: 1)}",
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

def fake_metadata_provenance(user_id, time = Time.zone.now)
  {
    'WGS_id' => { 'source' => 'user', 'id' => user_id, 'updated_at' => time },
    'ncbi_accession' => { 'source' => 'user', 'id' => user_id, 'updated_at' => time },
    'country' => { 'source' => 'user', 'id' => user_id, 'updated_at' => time },
    'food' => { 'source' => 'user', 'id' => user_id, 'updated_at' => time },
    'gender' => { 'source' => 'user', 'id' => user_id, 'updated_at' => time },
    'age' => { 'source' => 'user', 'id' => user_id, 'updated_at' => time },
    'onset' => { 'source' => 'user', 'id' => user_id, 'updated_at' => time },
    'earliest_date' => { 'source' => 'user', 'id' => user_id, 'updated_at' => time },
    'patient_sex' => { 'source' => 'user', 'id' => user_id, 'updated_at' => time },
    'patient_age' => { 'source' => 'user', 'id' => user_id, 'updated_at' => time },
    'insdc_accession' => { 'source' => 'user', 'id' => user_id, 'updated_at' => time }
  }
end

def fake_metadata_summary(sample_count)
  {
    'WGS_id' => sample_count,
    'ncbi_accession' => sample_count,
    'country' => sample_count,
    'food' => sample_count,
    'gender' => sample_count,
    'age' => sample_count,
    'onset' => sample_count,
    'earliest_date' => sample_count,
    'patient_sex' => sample_count,
    'patient_age' => sample_count,
    'insdc_accession' => sample_count
  }
end

def seed_samples(project, sample_count) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
  samples = []
  # round the project created_at to the nearest 1 / 12_228.0 seconds to ensure puid uniqueness
  interval = Rational(1, 12_228)
  project_created_at = Time.at((project.created_at.utc.to_r / interval).round * interval, in: 'UTC')
  sample_count.times do |x|
    timestamp = project_created_at + ((x + 1) * interval)
    samples << {
      puid: Irida::PersistentUniqueId.generate(object_class: Sample, time: timestamp),
      name: "#{project.namespace.parent.name}/#{project.name} Sample #{x + 1}",
      description: "This is a description for sample #{project.namespace.parent.name}/#{project.name} Sample #{x + 1}.",
      metadata: fake_metadata,
      metadata_provenance: fake_metadata_provenance(project.creator.id, timestamp),
      project_id: project.id,
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  seeded_samples = Sample.upsert_all(samples, unique_by: [:puid]) # rubocop:disable Rails/SkipsModelValidations

  Sample.where(id: seeded_samples.map { |row| row['id'] }).find_each do |sample|
    seed_attachments(sample)
  end

  seeded_samples.count
end

def seed_attachments(sample) # rubocop:disable Metrics/MethodLength
  Rails.logger.info "seeding... Sample: #{sample.name}, Attachments"

  attachment_timestamp = sample.created_at + (10 / 12_228.0)
  fwd_id = SecureRandom.uuid
  rev_id = SecureRandom.uuid
  puid = Irida::PersistentUniqueId.generate(object_class: Attachment, time: attachment_timestamp)

  attachments = [
    {
      id: fwd_id,
      puid: puid,
      attachable_id: sample.id,
      attachable_type: 'Sample',
      metadata: { type: 'illumina_pe', format: 'fastq', direction: 'forward', compression: 'gzip',
                  associated_attachment_id: rev_id },
      created_at: attachment_timestamp,
      updated_at: attachment_timestamp
    },
    {
      id: rev_id,
      puid: puid,
      attachable_id: sample.id,
      attachable_type: 'Sample',
      metadata: { type: 'illumina_pe', format: 'fastq', direction: 'reverse', compression: 'gzip',
                  associated_attachment_id: fwd_id },
      created_at: attachment_timestamp,
      updated_at: attachment_timestamp
    }
  ]

  Attachment.upsert_all(attachments) # rubocop:disable Rails/SkipsModelValidations

  activestorage_attachments = [
    {
      name: 'file',
      record_type: 'Attachment',
      record_id: fwd_id,
      blob_id: @illumina_pe_fwd,
      created_at: attachment_timestamp
    },
    {
      name: 'file',
      record_type: 'Attachment',
      record_id: rev_id,
      blob_id: @illumina_pe_rev,
      created_at: attachment_timestamp
    }
  ]

  ActiveStorage::Attachment.upsert_all(activestorage_attachments) # rubocop:disable Rails/SkipsModelValidations
end

def seed_group(group_params:, owner: nil, parent: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  sample_count = 0
  owner = User.find_by(email: group_params[:owner_email]) if group_params[:owner_email]

  raise 'Attempting to seed group without an owner.' if owner.blank?

  group = Groups::CreateService.new(
    owner,
    group_params.slice(:name, :path, :description).merge({ parent: })
  ).execute

  # seed the members using group_params[:members_by_role]
  if group_params[:member_emails_by_role] # rubocop:disable Style/SafeNavigation
    group_params[:member_emails_by_role].each do |access_level, email|
      seed_members(email, access_level, group)
    end
  end

  # seed the projects
  if group_params[:projects] # rubocop:disable Style/SafeNavigation
    group_params[:projects].each do |project_params|
      Rails.logger.info { "seeding... Group: #{group_params[:name]}, Project: #{project_params[:name]}" }
      # prevent project broadcasts
      sample_count += seed_project(project_params:, creator: owner, namespace: group)
    end
  end

  # seed the subgroups
  if group_params[:subgroups] # rubocop:disable Style/SafeNavigation
    group_params[:subgroups].each do |subgroup_params|
      sample_count += seed_group(group_params: subgroup_params, owner:, parent: group)
    end
  end

  group.update_columns(samples_count: sample_count, metadata_summary: fake_metadata_summary(sample_count)) # rubocop:disable Rails/SkipsModelValidations

  return sample_count unless parent.nil?

  group
end

def seed_workflow_executions # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  workflow_execution_basic = WorkflowExecution.create(
    metadata: { pipeline_id: 'phac-nml/iridanextexample', workflow_version: '1.0.3' },
    name: 'irida-next-example-basic',
    namespace_id: Sample.first.project.namespace.id,
    workflow_params: { assembler: 'stub' },
    workflow_type: 'NFL',
    workflow_type_version: 'DSL2',
    tags: [],
    workflow_engine: 'nextflow',
    workflow_engine_version: '24.10.3',
    workflow_engine_parameters: { '-r': 'dev' },
    workflow_url: 'https://github.com/phac-nml/iridanextexample',
    submitter: User.find_by(email: 'user1@email.com'),
    samples_workflow_executions_attributes: {
      '0': {
        sample_id: Sample.first.id,
        samplesheet_params: {
          sample: Sample.first.puid
        }
      }
    }
  )

  SamplesWorkflowExecution.create(
    samplesheet_params: { my_key1: 'my_value_1', my_key2: 'my_value_2' },
    sample: Sample.first,
    workflow_execution: workflow_execution_basic
  )

  workflow_execution_completed = WorkflowExecution.create(
    metadata: {
      pipeline_id: 'phac-nml/iridanextexample',
      workflow_version: '1.0.3'
    },
    name: 'irida-next-example-completed',
    namespace_id: Sample.first.project.namespace.id,
    workflow_params: { assembler: 'stub' },
    workflow_type: 'NFL',
    workflow_type_version: 'DSL2',
    tags: [],
    workflow_engine: 'nextflow',
    workflow_engine_version: '24.10.3',
    workflow_engine_parameters: { '-r': 'dev' },
    workflow_url: 'https://github.com/phac-nml/iridanextexample',
    submitter: User.find_by(email: 'user1@email.com'),
    blob_run_directory: 'this should be a generated key',
    state: :completed,
    samples_workflow_executions_attributes: {
      '0': {
        sample_id: Sample.first.id,
        samplesheet_params: {
          sample: Sample.first.puid
        }
      }
    }
  )

  SamplesWorkflowExecution.create(
    sample: Sample.first,
    workflow_execution: workflow_execution_completed
  )

  # Iterate over all files in tes/fixtures/fils/blob_outputs/normal and attach them to the workflow_execution_completed
  Dir.foreach(Rails.root.join('test/fixtures/files/blob_outputs/normal')) do |f|
    next unless File.file?(File.join('test/fixtures/files/blob_outputs/normal', f))

    blob = ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join('test/fixtures/files/blob_outputs/normal', f).open,
      filename: f.to_s
    ).signed_id
    attachment = workflow_execution_completed.outputs.build(file: blob)
    attachment.save!
  end
end

def seed_exports # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  current_year = Time.zone.now.year

  export_params = [
    {
      user: User.find_by(email: 'user0@email.com'),
      sample: Sample.find_by(name: "Bacillus anthracis/Outbreak #{current_year - 2} Sample 10")
    },
    {
      user: User.find_by(email: 'user1@email.com'),
      sample: Sample.find_by(name: "Bartonella henselae/Outbreak #{current_year - 2} Sample 10")
    },
    {
      user: User.find_by(email: 'user2@email.com'),
      sample: Sample.find_by(name: "Bordetella pertussis/Outbreak #{current_year - 2} Sample 10")
    },
    {
      user: User.find_by(email: 'user3@email.com'),
      sample: Sample.find_by(name: "Borrelia burgdorferi/Outbreak #{current_year - 2} Sample 10")
    },
    {
      user: User.find_by(email: 'user4@email.com'),
      sample: Sample.find_by(name: "Brucella abortus/Outbreak #{current_year - 2} Sample 10")
    },
    {
      user: User.find_by(email: 'user5@email.com'),
      sample: Sample.find_by(name: "Campylobacter jejuni/Outbreak #{current_year - 2} Sample 10")
    },
    {
      user: User.find_by(email: 'user6@email.com'),
      sample: Sample.find_by(name: "Yersinia pestis/Outbreak #{current_year - 2} Sample 10")
    },
    {
      user: User.find_by(email: 'user7@email.com'),
      sample: Sample.find_by(name: "Vibrio cholerae/Outbreak #{current_year - 1} Sample 10")
    }
  ]
  export_params.each_with_index do |export_param, index| # rubocop:disable Metrics/BlockLength
    namespace_id = index.even? ? export_param[:sample].project.namespace.id : export_param[:sample].project.parent.id
    metadata_fields = if index.even?
                        export_param[:sample].project.namespace.metadata_fields
                      else
                        export_param[:sample].project.parent.metadata_fields
                      end
    # export with status=processing and no attachment
    DataExport.create(
      user: export_param[:user],
      name: index.even? ? "Seeded sample export #{index + 1}" : nil,
      export_parameters: { ids: [export_param[:sample].id], namespace_id:,
                           attachment_formats: Attachment::FORMAT_REGEX.keys },
      status: 'processing',
      export_type: 'sample',
      email_notification: index.even? && true
    )

    linelist_export = DataExport.create(
      user: export_param[:user],
      name: index.even? ?  "Seeded linelist export #{index + 1}" : nil,
      export_parameters: { ids: [export_param[:sample].id],
                           namespace_id:,
                           metadata_fields:,
                           linelist_format: index.even? ? 'xlsx' : 'csv' },
      status: 'processing',
      export_type: 'linelist',
      email_notification: index.even? || true
    )

    # export with status=ready with zip attachment
    sample_export = DataExport.create(
      user: export_param[:user],
      name: index.even? ?  nil : "Seeded sample export #{index + 1}",
      export_parameters: { ids: [export_param[:sample].id], namespace_id:,
                           attachment_formats: Attachment::FORMAT_REGEX.keys },
      status: 'processing',
      export_type: 'sample',
      email_notification: index.even? || true
    )
    DataExports::CreateJob.perform_now(sample_export)

    DataExport.create(
      user: export_param[:user],
      name: index.even? ?  nil : "Seeded linelist export #{index + 1}",
      export_parameters: { ids: [export_param[:sample].id],
                           namespace_id:,
                           metadata_fields:,
                           linelist_format: index.even? ? 'csv' : 'xlsx' },
      status: 'processing',
      export_type: 'linelist',
      email_notification: index.even? || true
    )
    DataExports::CreateJob.perform_now(linelist_export)
  end
end

if Rails.env.development?
  current_year = Time.zone.now.year

  password_hash = Devise::Encryptor.digest(User, 'password1')

  starting_created_at = 1.week.ago

  users = []
  10.times do |x|
    users << {
      email: "user#{x}@email.com",
      encrypted_password: password_hash,
      first_name: 'User',
      last_name: x.to_s,
      created_at: starting_created_at + x.minutes,
      updated_at: starting_created_at + x.minutes
    }
  end
  seeded_users = User.upsert_all(users, unique_by: [:email]) # rubocop:disable Rails/SkipsModelValidations

  user_namespaces = User.where(id: seeded_users.map { |row| row['id'] }).map do |user|
    {
      name: user.email,
      puid: Irida::PersistentUniqueId.generate(object_class: Namespaces::UserNamespace, time: user.created_at),
      owner_id: user.id,
      created_at: user.created_at,
      updated_at: user.created_at
    }
  end
  seeded_user_namespaces = Namespaces::UserNamespace.upsert_all(user_namespaces, unique_by: [:puid]) # rubocop:disable Rails/SkipsModelValidations

  user_namespaces_routes = Namespaces::UserNamespace.where(id: seeded_user_namespaces.map do |row|
    row['id']
  end).map do |user_namespace|
    {
      name: user_namespace.name,
      path: format('%<email>s', email: user_namespace.name).sub!('@', '_at_'),
      source_id: user_namespace.id,
      source_type: 'Namespace',
      created_at: user_namespace.created_at,
      updated_at: user_namespace.created_at
    }
  end
  Route.upsert_all(user_namespaces_routes, unique_by: [:path]) # rubocop:disable Rails/SkipsModelValidations

  # Workflow Metadata
  #
  # {
  #   workflow_name: String Required
  #   workflow_version: String Required
  # }

  # generic_workflow_metadata_objects = [
  #   {workflow_name: 'my_workflow_name_1', workflow_version: 'my_workflow_version_1'},
  #   {workflow_name: 'my_workflow_name_1', workflow_version: 'my_workflow_version_1'}
  # ]

  # Various Hashes for workflow executions
  #
  # {
  #   any_keys: String Optional
  # }

  # generic_workflow_execution_params_hashes = [
  #   { my_key1: 'my_value_1', my_key2: 'my_value_2' },
  #   { my_key3: 'my_value_3' },
  #   { my_key4: 'my_value_4', my_key5: 'my_value_5' },
  #   { my_key6: 'my_value_6' },
  #   { my_key7: 'my_value_7', my_key8: 'my_value_8' },
  #   { my_key9: 'my_value_9' }
  # ]

  # WorkflowExecution
  #
  # {
  #   metadata: WorkflowMetadata Required
  #   workflow_params: Hash
  #   workflow_type: "NFL"
  #   workflow_type_version: "DSL2"
  #   tags: [String]
  #   workflow_engine: "nextflow"
  #   workflow_engine_version: "24.10.3"
  #   workflow_engine_parameters: Hash
  #   workflow_url: String
  #   run_id: String
  #   submitter: User Required
  # }

  # generic_workflow_execution_hashes = [
  #   {
  #     metadata: generic_workflow_metadata_objects[0],
  #     workflow_params: generic_workflow_execution_params_hashes[0],
  #     workflow_type: "NFL"
  #     workflow_type_version: "DSL2"
  #     tags: %w[my_tag_1 my_tag_2],
  #     workflow_engine: "nextflow"
  #     workflow_engine_version: "24.10.3"
  #     workflow_engine_parameters: generic_workflow_execution_params_hashes[1],
  #     workflow_url: 'my_workflow_url',
  #     run_id: 'my_run_id',
  #     submitter: User.find(1)
  #   },
  #   {
  #     metadata: generic_workflow_metadata_objects[1],
  #     workflow_params: generic_workflow_execution_params_hashes[2],
  #     workflow_type: "NFL"
  #     workflow_type_version: "DSL2"
  #     tags: %w[my_tag_3 my_tag_4],
  #     workflow_engine: "nextflow"
  #     workflow_engine_version: "24.10.3"
  #     workflow_engine_parameters: generic_workflow_execution_params_hashes[3],
  #     workflow_url: 'my_workflow_url_2',
  #     run_id: 'my_run_id_2',
  #     submitter: User.find(2)
  #   }
  # ]

  # generic_workflow_execution_hashes.each do |workflow_execution_params|
  #   WorkflowExecution.create(
  #     metadata: workflow_execution_params[:metadata],
  #     workflow_params: workflow_execution_params[:workflow_params],
  #     workflow_type: "NFL"
  #     workflow_type_version: "DSL2"
  #     tags: workflow_execution_params[:tags],
  #     workflow_engine: "nextflow"
  #     workflow_engine_version: "24.10.3"
  #     workflow_engine_parameters: workflow_execution_params[:workflow_engine_parameters],
  #     workflow_url: workflow_execution_params[:workflow_url],
  #     run_id: workflow_execution_params[:run_id],
  #     submitter: workflow_execution_params[:submitter]
  #   )
  # end

  # Once a creator service is implimented we can create workflow executions something like this
  # WorkflowExecution.create(
  #   metadata: generic_workflow_metadata_objects[0],
  #   workflow_params: generic_workflow_execution_params_hashes[0],
  #   workflow_type: "NFL"
  #   workflow_type_version: "DSL2"
  #   tags: %w[my_tag_1 my_tag_2],
  #   workflow_engine: "nextflow"
  #   workflow_engine_version: "24.10.3"
  #   workflow_engine_parameters: generic_workflow_execution_params_hashes[1],
  #   workflow_url: 'my_workflow_url',
  #   run_id: 'my_run_id',
  #   submitter: User.find(1)
  # )

  # SamplesWorkflowExecution
  #
  # {
  #   samplesheet_params: Hash
  #   sample: Sample Required
  #   workflow_execution: WorkflowExecution Required
  # }

  # generic_samples_workflow_execution_hashes = [
  #   {
  #     samplesheet_params: generic_workflow_execution_params_hashes[4],
  #     sample: Sample.find(1),
  #     workflow_execution: WorkflowExecution.find(1)
  #   },
  #   {
  #     samplesheet_params: generic_workflow_execution_params_hashes[5],
  #     sample: Sample.find(2),
  #     workflow_execution: WorkflowExecution.find(2)
  #   }
  # ]

  # generic_samples_workflow_execution_hashes.each do |samples_workflow_execution_params|
  #   SamplesWorkflowExecution.create(**samples_workflow_execution_params)
  # end

  # Group Params Hash
  #
  # {
  #   name: String Required
  #   path: String Required
  #   owner_email: String Required
  #   member_emails_by_role: Hash Optional (keys Roles, values Array of emails)
  #   subgroups: Array Optional of Group Params Hash
  #   projects: Array Optional of Project Params Hash
  # }

  # Project Params Hash
  #
  # {
  #   name: String Required
  #   path: String Required
  #   sample_count: Integer Required
  #   member_emails_by_role: Hash Optional (keys Roles, values Array of emails)
  # }

  group_owner_emails = [
    users[0][:email],
    users[1][:email],
    users[2][:email],
    users[3][:email],
    users[4][:email],
    users[5][:email]
  ]

  member_emails_by_role = {
    Maintainer: [users[6][:email]],
    Analyst: [users[7][:email]],
    Guest: [users[8][:email]]
  }

  default_sample_count = 1000

  generic_projects = [
    {
      name: "Outbreak #{current_year - 2}",
      path: "outbreak-#{current_year - 2}",
      description: "This is a description for project Outbreak #{current_year - 2}",
      sample_count: default_sample_count,
      member_emails_by_role:

    },
    {
      name: "Outbreak #{current_year - 1}",
      path: "outbreak-#{current_year - 1}",
      description: "This is a description for project Outbreak #{current_year - 1}",
      sample_count: default_sample_count,
      member_emails_by_role:
    }
  ]

  groups = [
    { name: 'Bacillus', path: 'bacillus', owner_email: group_owner_emails[0],
      member_emails_by_role:,
      subgroups: [
        { name: 'Bacillus anthracis', path: 'bacillus-anthracis', projects: generic_projects },
        { name: 'Bacillus cereus', path: 'bacillus-cereus', projects: generic_projects }
      ] },
    { name: 'Bartonella', path: 'bartonella', owner_email: group_owner_emails[1],
      member_emails_by_role:,
      subgroups: [
        { name: 'Bartonella henselae', path: 'bartonella-henselae', projects: generic_projects },
        { name: 'Bartonella quintana', path: 'bartonella-quintana', projects: generic_projects }
      ] },
    { name: 'Bordetella', path: 'bordetella', owner_email: group_owner_emails[2],
      member_emails_by_role:,
      subgroups: [
        { name: 'Bordetella pertussis', path: 'bordetella-pertussis', projects: generic_projects }
      ] },
    { name: 'Borrelia', path: 'borrelia', owner_email: group_owner_emails[3],
      member_emails_by_role:,
      subgroups: [
        { name: 'Borrelia burgdorferi', path: 'borrelia-burgdorferi', projects: generic_projects },
        { name: 'Borrelia garinii', path: 'borrelia-garinii', projects: generic_projects },
        { name: 'Borrelia afzelii', path: 'borrelia-afzelii', projects: generic_projects },
        { name: 'Borrelia recurrentis', path: 'borrelia-recurrentis', projects: generic_projects }
      ] },
    { name: 'Brucella', path: 'brucella', owner_email: group_owner_emails[4],
      member_emails_by_role:,
      subgroups: [
        { name: 'Brucella abortus', path: 'brucella-abortus', projects: generic_projects },
        { name: 'Brucella canis', path: 'brucella-canis', projects: generic_projects },
        { name: 'Brucella melitensis', path: 'brucella-melitensis', projects: generic_projects },
        { name: 'Brucella suis', path: 'brucella-suis', projects: generic_projects }
      ] },
    { name: 'Campylobacter', path: 'campylobacter', owner_email: group_owner_emails[5],
      member_emails_by_role:,
      subgroups: [
        { name: 'Campylobacter jejuni', path: 'campylobacter-jejuni', projects: generic_projects }
      ] },
    { name: 'Chlamydia and Chlamydophila', path: 'chlamydia-chlamydophila', owner_email: group_owner_emails[0],
      member_emails_by_role:,
      subgroups: [
        { name: 'Chlamydia pneumoniae', path: 'chlamydia-pneumoniae', projects: generic_projects },
        { name: 'Chlamydia trachomatis', path: 'chlamydia-trachomatis', projects: generic_projects },
        { name: 'Chlamydophila psittaci', path: 'chlamydophila-psittaci', projects: generic_projects }
      ] },
    { name: 'Clostridium', path: 'clostridium', owner_email: group_owner_emails[1],
      member_emails_by_role:,
      subgroups: [
        { name: 'Clostridium botulinum', path: 'clostridium-botulinum', projects: generic_projects },
        { name: 'Clostridium difficile', path: 'clostridium-difficile', projects: generic_projects },
        { name: 'Clostridium perfringens', path: 'clostridium-perfringens', projects: generic_projects },
        { name: 'Clostridium tetani', path: 'clostridium-tetani', projects: generic_projects }
      ] },
    { name: 'Corynebacterium', path: 'corynebacterium', owner_email: group_owner_emails[2],
      member_emails_by_role:,
      subgroups: [
        { name: 'Corynebacterium diphtheriae', path: 'corynebacterium-diphtheriae', projects: generic_projects }
      ] },
    { name: 'Enterococcus', path: 'enterococcus', owner_email: group_owner_emails[3],
      member_emails_by_role:,
      subgroups: [
        { name: 'Enterococcus faecalis', path: 'enterococcus-faecalis', projects: generic_projects },
        { name: 'Enterococcus faecium', path: 'enterococcus-faecium', projects: generic_projects }
      ] },
    { name: 'Escherichia', path: 'Escherichia', owner_email: group_owner_emails[4],
      member_emails_by_role:,
      subgroups: [
        { name: 'Escherichia coli', path: 'escherichia-coli', projects: generic_projects }
      ] },
    { name: 'Francisella', path: 'francisella', owner_email: group_owner_emails[5],
      member_emails_by_role:,
      subgroups: [
        { name: 'Francisella tularensis', path: 'francisella-tularensis', projects: generic_projects }
      ] },
    { name: 'Haemophilus', path: 'haemophilus', owner_email: group_owner_emails[0],
      member_emails_by_role:,
      subgroups: [
        { name: 'Haemophilus influenzae', path: 'haemophilus-influenzae', projects: generic_projects }
      ] },
    { name: 'Helicobacter', path: 'helicobacter', owner_email: group_owner_emails[1],
      member_emails_by_role:,
      subgroups: [
        { name: 'Helicobacter pylori', path: 'helicobacter-pylori', projects: generic_projects }
      ] },
    { name: 'Legionella', path: 'legionella', owner_email: group_owner_emails[2],
      member_emails_by_role:,
      subgroups: [
        { name: 'Legionella pneumophila', path: 'legionella-pneumophila', projects: generic_projects }
      ] },
    { name: 'Leptospira', path: 'leptospira', owner_email: group_owner_emails[3],
      member_emails_by_role:,
      subgroups: [
        { name: 'Leptospira interrogans', path: 'leptospira-interrogans', projects: generic_projects },
        { name: 'Leptospira santarosai', path: 'leptospira-santarosai', projects: generic_projects },
        { name: 'Leptospira weilii', path: 'leptospira-weilii', projects: generic_projects },
        { name: 'Leptospira noguchii', path: 'leptospira-noguchii', projects: generic_projects }
      ] },
    { name: 'Listeria', path: 'listeria', owner_email: group_owner_emails[4],
      member_emails_by_role:,
      subgroups: [
        { name: 'Listeria monocytogenes', path: 'listeria-monocytogenes', projects: generic_projects }
      ] },
    { name: 'Mycobacterium', path: 'mycobacterium', owner_email: group_owner_emails[5],
      member_emails_by_role:,
      subgroups: [
        { name: 'Mycobacterium leprae', path: 'mycobacterium-leprae', projects: generic_projects },
        { name: 'Mycobacterium tuberculosis', path: 'mycobacterium-tuberculosis', projects: generic_projects },
        { name: 'Mycobacterium ulcerans', path: 'mycobacterium-ulcerans', projects: generic_projects }
      ] },
    { name: 'Mycoplasma', path: 'mycoplasma', owner_email: group_owner_emails[0],
      member_emails_by_role:,
      subgroups: [
        { name: 'Mycoplasma pneumoniae', path: 'mycoplasma-pneumoniae', projects: generic_projects }
      ] },
    { name: 'Neisseria', path: 'neisseria', owner_email: group_owner_emails[1],
      member_emails_by_role:,
      subgroups: [
        { name: 'Neisseria gonorrhoeae', path: 'neisseria-gonorrhoeae', projects: generic_projects },
        { name: 'Neisseria meningitidis', path: 'neisseria-meningitidis', projects: generic_projects }
      ] },
    { name: 'Pseudomonas', path: 'pseudomonas', owner_email: group_owner_emails[2],
      member_emails_by_role:,
      subgroups: [
        { name: 'Pseudomonas aeruginosa', path: 'pseudomonas-aeruginosa', projects: generic_projects }
      ] },
    { name: 'Rickettsia', path: 'rickettsia', owner_email: group_owner_emails[3],
      member_emails_by_role:,
      subgroups: [
        { name: 'Rickettsia rickettsii', path: 'rickettsia-rickettsii', projects: generic_projects }
      ] },
    { name: 'Salmonella', path: 'salmonella', owner_email: group_owner_emails[4],
      member_emails_by_role:,
      subgroups: [
        { name: 'Salmonella typhi', path: 'salmonella-typhi', projects: generic_projects },
        { name: 'Salmonella typhimurium', path: 'salmonella-typhimurium', projects: generic_projects }
      ] },
    { name: 'Shigella', path: 'shigella', owner_email: group_owner_emails[5],
      member_emails_by_role:,
      subgroups: [
        { name: 'Shigella sonnei', path: 'shigella-sonnei', projects: generic_projects }
      ] },
    { name: 'Staphylococcus', path: 'staphylococcus', owner_email: group_owner_emails[0],
      member_emails_by_role:,
      subgroups: [
        { name: 'Staphylococcus aureus', path: 'staphylococcus-aureus', projects: generic_projects },
        { name: 'Staphylococcus epidermidis', path: 'staphylococcus-epidermidis', projects: generic_projects },
        { name: 'Staphylococcus saprophyticus', path: 'staphylococcus-saprophyticus', projects: generic_projects }
      ] },
    { name: 'Streptococcus', path: 'streptococcus', owner_email: group_owner_emails[1],
      member_emails_by_role:,
      subgroups: [
        { name: 'Streptococcus agalactiae', path: 'streptococcus-agalactiae', projects: generic_projects },
        { name: 'Streptococcus pneumoniae', path: 'streptococcus-pneumoniae', projects: generic_projects },
        { name: 'Streptococcus pyogenes', path: 'streptococcus-pyogenes', projects: generic_projects,
          subgroups: [
            { name: 'Streptococcus pyogenes M1', path: 'streptococcus-pyogenes-m1', projects: generic_projects },
            { name: 'Streptococcus pyogenes M3', path: 'streptococcus-pyogenes-m3', projects: generic_projects },
            { name: 'Streptococcus pyogenes M5', path: 'streptococcus-pyogenes-m5', projects: generic_projects },
            { name: 'Streptococcus pyogenes M18', path: 'streptococcus-pyogenes-m18', projects: generic_projects },
            { name: 'Streptococcus pyogenes M28', path: 'streptococcus-pyogenes-m28', projects: generic_projects },
            { name: 'Streptococcus pyogenes M41', path: 'streptococcus-pyogenes-m41', projects: generic_projects },
            { name: 'Streptococcus pyogenes M49', path: 'streptococcus-pyogenes-m49', projects: generic_projects },
            { name: 'Streptococcus pyogenes M58', path: 'streptococcus-pyogenes-m58', projects: generic_projects },
            { name: 'Streptococcus pyogenes M60', path: 'streptococcus-pyogenes-m60', projects: generic_projects },
            { name: 'Streptococcus pyogenes M66', path: 'streptococcus-pyogenes-m66', projects: generic_projects },
            { name: 'Streptococcus pyogenes M75', path: 'streptococcus-pyogenes-m75', projects: generic_projects },
            { name: 'Streptococcus pyogenes M77', path: 'streptococcus-pyogenes-m77', projects: generic_projects },
            { name: 'Streptococcus pyogenes M89', path: 'streptococcus-pyogenes-m89', projects: generic_projects },
            { name: 'Streptococcus pyogenes M92', path: 'streptococcus-pyogenes-m92', projects: generic_projects }
          ] }
      ] },
    { name: 'Treponema', path: 'treponema-pallidum', owner_email: group_owner_emails[2],
      member_emails_by_role:,
      subgroups: [
        { name: 'Treponema pallidum', path: 'treponema-pallidum', projects: generic_projects }
      ] },
    { name: 'Ureaplasma', path: 'Ureaplasma', owner_email: group_owner_emails[3],
      member_emails_by_role:,
      subgroups: [
        { name: 'Ureaplasma urealyticum', path: 'ureaplasma-urealyticum', projects: generic_projects }
      ] },
    { name: 'Vibrio', path: 'vibrio', owner_email: group_owner_emails[4],
      member_emails_by_role:,
      subgroups: [
        { name: 'Vibrio cholerae', path: 'vibrio-cholerae', projects: generic_projects }
      ] },
    { name: 'Yersinia', path: 'yersinia', owner_email: group_owner_emails[5],
      member_emails_by_role:,
      subgroups: [
        { name: 'Yersinia pestis', path: 'yersinia-pestis', projects: generic_projects },
        { name: 'Yersinia enterocolitica', path: 'yersinia-enterocolitica', projects: generic_projects },
        { name: 'Yersinia pseudotuberculosis', path: 'yersinia-pseudotuberculosis', projects: generic_projects }
      ] }
  ]

  seeded_parent_groups = groups.map do |group|
    seed_group(group_params: group)
  end

  # Create namespace group links (group to group)
  seeded_parent_groups.each do |namespace|
    # link each namespace to 5 other random namespaces with analyst access
    groups_to_link_to_namespace = (seeded_parent_groups - [namespace]).sample(5)
    groups_to_link_to_namespace.each do |group_to_link_to_namespace|
      seed_namespace_group_links(namespace.owner, namespace, group_to_link_to_namespace, Member::AccessLevel::ANALYST)
    end
  end

  # Create a direct namespace group link for each project
  all_projects = Project.all

  all_projects.each do |proj|
    direct_group_to_link_to_namespace = seeded_parent_groups.last
    seed_namespace_group_links(proj.namespace.owner, proj.namespace, direct_group_to_link_to_namespace,
                               Member::AccessLevel::ANALYST)
  end
  # prevent workflow and workflow attachment broadcasts
  Attachment.suppressing_turbo_broadcasts do
    WorkflowExecution.suppressing_turbo_broadcasts do
      seed_workflow_executions
    end
  end
  # prevent data export broadcasts
  DataExport.suppressing_turbo_broadcasts do
    seed_exports
  end
end
