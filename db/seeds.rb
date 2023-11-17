# frozen_string_literal: true

@namespace_group_link_expiry_date = (Time.zone.today + 14).strftime('%Y-%m-%d')

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Limit the number of file attachments to add when seeding to reduce time.
@sample_attachment_count = 0
@sample_attachment_limit = 20

def seed_project(project_params:, creator:, namespace:)
  project = Projects::CreateService.new(creator,
                                        {
                                          namespace_attributes: project_params.slice(
                                            :name,
                                            :path
                                          ).merge({ parent: namespace, owner: creator })
                                        }).execute

  # seed the project members
  if project_params[:member_emails_by_role] # rubocop:disable Style/SafeNavigation
    project_params[:member_emails_by_role].each do |access_level, email|
      seed_members(email, access_level, project.namespace)
    end
  end

  # seed the project samples
  seed_samples(project, project_params[:sample_count]) if project_params[:sample_count]
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

def seed_samples(project, sample_count)
  1.upto(sample_count) do |i|
    sample = Samples::CreateService.new(
      project.creator, project,
      { name: "#{project.namespace.parent.name}/#{project.name} Sample #{i}",
        description: "This is a description for sample #{project.namespace.parent.name}/#{project.name} Sample #{i}." }
    ).execute
    seed_attachments(sample) if @sample_attachment_count < @sample_attachment_limit
  end
end

def seed_attachments(sample)
  Rails.logger.info "seeding attachments... #{@sample_attachment_count}/#{@sample_attachment_limit}"
  sequencing_files.each do |f|
    a = sample.attachments.build
    a.file.attach(io: Rails.root.join('test/fixtures/files', f).open, filename: f.to_s)
    a.save!
  end
  @sample_attachment_count += 1
end

def sequencing_files
  Rails.root.join('test/fixtures/files').entries.select do |f|
    ((File.file?(File.join('test/fixtures/files/', f)) && f.to_s.end_with?('gz')) || f.to_s.end_with?('fastq'))
  end
end

def seed_group(group_params:, owner: nil, parent: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
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
      seed_project(project_params:, creator: owner, namespace: group)
    end
  end

  # seed the subgroups
  return unless group_params[:subgroups]

  group_params[:subgroups].each do |subgroup_params|
    seed_group(group_params: subgroup_params, owner:, parent: group)
  end
end

if Rails.env.development?
  current_year = Time.zone.now.year

  users = [
    {
      email: 'admin@email.com',
      password: 'password1',
      password_confirmation: 'password1',
      first_name: 'ad',
      last_name: 'min',
      personal_access_tokens: [
        { name: 'API r/w Token', scopes: ['api'],
          token_digest: Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'zs83sKD3jeysfnr_kgu9') },
        { name: 'API read only Token', scopes: ['read_api'],
          token_digest: Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'yK1euURqVRtQ1D-3uKsW') }
      ]
    },
    {
      email: 'user1@email.com',
      first_name: 'user',
      last_name: 'one',
      password: 'password1',
      password_confirmation: 'password1'
    },
    {
      email: 'user2@email.com',
      first_name: 'user',
      last_name: 'two',
      password: 'password1',
      password_confirmation: 'password1'
    },
    {
      email: 'user3@email.com',
      first_name: 'user',
      last_name: 'three',
      password: 'password1',
      password_confirmation: 'password1'
    },
    {
      email: 'user4@email.com',
      first_name: 'user',
      last_name: 'four',
      password: 'password1',
      password_confirmation: 'password1'
    },
    {
      email: 'user5@email.com',
      first_name: 'user',
      last_name: 'five',
      password: 'password1',
      password_confirmation: 'password1'
    }, {
      email: 'user6@email.com',
      first_name: 'user',
      last_name: 'six',
      password: 'password1',
      password_confirmation: 'password1'
    },
    {
      email: 'user7@email.com',
      first_name: 'user',
      last_name: 'seven',
      password: 'password1',
      password_confirmation: 'password1'
    },
    {
      email: 'user8@email.com',
      first_name: 'user',
      last_name: 'eight',
      password: 'password1',
      password_confirmation: 'password1'
    },
    {
      email: 'user9@email.com',
      first_name: 'user',
      last_name: 'nine',
      password: 'password1',
      password_confirmation: 'password1'
    }
  ]

  users.each do |user_params|
    user = User.create_with(user_params.slice(
                              :password,
                              :password_confirmation
                            )).find_or_create_by!(
                              email: user_params[:email],
                              first_name: user_params[:first_name],
                              last_name: user_params[:last_name]
                            )
    next unless user_params[:personal_access_tokens]

    user_params[:personal_access_tokens].each do |pat|
      PersonalAccessToken.find_or_create_by!(name: pat[:name], scopes: pat[:scopes], user:,
                                             token_digest: pat[:token_digest])
    end
  end

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

  generic_projects = [
    {
      name: "Outbreak #{current_year - 2}",
      path: "outbreak-#{current_year - 2}",
      sample_count: 10,
      member_emails_by_role:

    },
    {
      name: "Outbreak #{current_year - 1}",
      path: "outbreak-#{current_year - 1}",
      sample_count: 10,
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

  groups.each do |group|
    seed_group(group_params: group)
  end

  # Create namespace group links (group to group)
  all_groups_without_parent = Group.where(parent: nil)

  all_groups_without_parent.each do |namespace|
    groups_to_link_to_namespace = all_groups_without_parent.where.not(id: namespace.self_and_ancestor_ids)
                                                           .where(parent: nil).limit(5)
    groups_to_link_to_namespace.each do |group_to_link_to_namespace|
      seed_namespace_group_links(namespace.owner, namespace, group_to_link_to_namespace, Member::AccessLevel::ANALYST)
    end
  end

  # Create a direct namespace group link for each project
  all_projects = Project.all

  all_projects.each do |proj|
    direct_group_to_link_to_namespace = all_groups_without_parent.last
    seed_namespace_group_links(proj.namespace.owner, proj.namespace, direct_group_to_link_to_namespace,
                               Member::AccessLevel::ANALYST)
  end
end
