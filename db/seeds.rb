# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

if Rails.env.development?
  current_year = Time.zone.now.year

  genus_listing = [{ Bacillus: ['Bacillus anthracis', 'Bacillus cereus'] },
                   { Bartonella: ['Bartonella henselae', 'Bartonella quintana'] },
                   { Bordetella: ['Bordetella pertussis'] },
                   { Borrelia: ['Borrelia burgdorferi', 'Borrelia garinii', 'Borrelia afzelii',
                                'Borrelia recurrentis'] },
                   { Brucella: ['Brucella abortus', 'Brucella canis', 'Brucella melitensis', 'Brucella suis'] },
                   { Campylobacter: ['Campylobacter jejuni'] },
                   { 'Chlamydia and Chlamydophila': ['Chlamydia pneumoniae', 'Chlamydia trachomatis',
                                                     'Chlamydophila psittaci'] },
                   { Clostridium: ['Clostridium botulinum', 'Clostridium difficile', 'Clostridium perfringens',
                                   'Clostridium tetani'] },
                   { Corynebacterium: ['Corynebacterium diphtheriae'] },
                   { Enterococcus: ['Enterococcus faecalis', 'Enterococcus faecium'] },
                   { Escherichia: ['Escherichia coli'] },
                   { Francisella: ['Francisella tularensis'] },
                   { Haemophilus: ['Haemophilus influenzae'] },
                   { Helicobacter: ['Helicobacter pylori'] },
                   { Legionella: ['Legionella pneumophila'] },
                   { Leptospira: ['Leptospira interrogans', 'Leptospira santarosai', 'Leptospira weilii',
                                  'Leptospira noguchii'] },
                   { Listeria: ['Listeria monocytogenes'] },
                   { Mycobacterium: ['Mycobacterium leprae', 'Mycobacterium tuberculosis', 'Mycobacterium ulcerans'] },
                   { Mycoplasma: ['Mycoplasma pneumoniae'] },
                   { Neisseria: ['Neisseria gonorrhoeae', 'Neisseria meningitidis'] },
                   { Pseudomonas: ['Pseudomonas aeruginosa'] },
                   { Rickettsia: ['Rickettsia rickettsii'] },
                   { Salmonella: ['Salmonella typhi', 'Salmonella typhimurium'] },
                   { Shigella: ['Shigella sonnei'] },
                   { Staphylococcus: ['Staphylococcus aureus', 'Staphylococcus epidermidis',
                                      'Staphylococcus saprophyticus'] },
                   { Streptococcus: ['Streptococcus agalactiae', 'Streptococcus pneumoniae',
                                     'Streptococcus pyogenes'] },
                   { Treponema: ['Treponema pallidum'] },
                   { Ureaplasma: ['Ureaplasma urealyticum'] },
                   { Vibrio: ['Vibrio cholerae'] },
                   { Yersinia: ['Yersinia pestis', 'Yersinia enterocolitica', 'Yersinia pseudotuberculosis'] }]

  project_listing = [{ Outbreak: [(current_year - 2).to_s, (current_year - 1).to_s] },
                     { Surveillance: [(current_year - 2).to_s, (current_year - 1).to_s] }]

  # Users
  User.create!({ email: 'admin@email.com', password: 'password1', password_confirmation: 'password1' })

  1.upto(10) do |i|
    User.create!({ email: "user#{i}@email.com", password: 'password1', password_confirmation: 'password1' })
  end

  users = User.all

  users.each do |user| # rubocop:disable Metrics/BlockLength
    # Groups
    genus_listing.each do |genus|
      group_name = "#{genus.keys.first} #{user.id}"
      group_path = if group_name.include?(' ')
                     group_name.downcase.gsub(' ', '-')
                   else
                     group_name
                   end
      parent_group = Groups::CreateService.new(user,
                                               { name: group_name,
                                                 path: group_path,
                                                 description: "This is a description the #{group_name} group." }).execute
      subgroup_names = genus.values.first
      # Subgroups
      subgroup_names.each do |subgroup|
        Groups::CreateService.new(user, { name: subgroup, path: subgroup.downcase.gsub(' ', '-'),
                                          description: "This is a description for the subgroup #{subgroup}.",
                                          parent: parent_group }).execute
      end
    end

    groups = Group.where(owner: user)
    available_users = users.to_a - [user]

    groups.each do |group|
      # Group Members
      available_users.each do |available_user|
        Members::CreateService.new(user, group, { user: available_user,
                                                  access_level: Member::AccessLevel::GUEST }).execute
      end

      project_listing.each do |proj|
        years = proj.values.first

        years.each do |year|
          # Projects
          proj_name = "#{proj.keys.first} #{year}"
          proj_path = "#{proj.keys.first.downcase}-#{year}"
          project = Projects::CreateService.new(user, { namespace_attributes: {
                                                  name: proj_name, path: proj_path,
                                                  description: "This is a description for project #{proj_name}.",
                                                  parent: group
                                                } }).execute

          # Project Members
          available_users.each do |available_user|
            Members::CreateService.new(user, project.namespace, { user: available_user,
                                                                  access_level: Member::AccessLevel::GUEST }).execute
          end

          # Samples
          1.upto(10) do |i|
            Samples::CreateService.new(user, project,
                                       { name: "#{group.name} #{i}",
                                         description: "This is a description for sample #{group.name} #{i}." }).execute
          end
        end
      end
    end
  end

end
