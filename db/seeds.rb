# frozen_string_literal: true

# This file creates development seed data for Ledgoria
# Run with: bin/rails db:seed
#
# NOTE: This seed file requires models to be implemented.
# It will be functional after Sprint 1 when models are created.

puts "Seeding database..."

# =============================================================================
# Organization
# =============================================================================
puts "Creating organization..."

org = Organization.find_or_create_by!(subdomain: "acme") do |o|
  o.name = "Acme Corporation"
  o.timezone = "America/New_York"
  o.default_currency = "USD"
  o.default_locale = "en"
  o.settings = {
    "features" => {
      "eeoc_collection" => true,
      "self_scheduling" => true,
      "offer_approvals" => true
    },
    "branding" => {
      "primary_color" => "#3B82F6",
      "logo_url" => nil
    }
  }
  o.plan = "professional"
end

puts "  Created: #{org.name} (#{org.subdomain})"

# =============================================================================
# Roles
# =============================================================================
puts "Creating roles..."

roles = {}

[
  { name: "admin", description: "Full system access", system_role: true },
  { name: "recruiter", description: "Full recruiting access", system_role: true },
  { name: "hiring_manager", description: "Job and candidate management", system_role: true },
  { name: "interviewer", description: "Interview and feedback access", system_role: true }
].each do |role_attrs|
  roles[role_attrs[:name]] = Role.find_or_create_by!(
    organization: org,
    name: role_attrs[:name]
  ) do |r|
    r.description = role_attrs[:description]
    r.system_role = role_attrs[:system_role]
    r.permissions = {}
  end
  puts "  Created role: #{role_attrs[:name]}"
end

# =============================================================================
# Users
# =============================================================================
puts "Creating users..."

users = {}

[
  { email: "admin@acme.test", first_name: "Alice", last_name: "Admin", role: "admin" },
  { email: "recruiter@acme.test", first_name: "Rachel", last_name: "Recruiter", role: "recruiter" },
  { email: "recruiter2@acme.test", first_name: "Ryan", last_name: "Recruiter", role: "recruiter" },
  { email: "hiring.manager@acme.test", first_name: "Henry", last_name: "Manager", role: "hiring_manager" },
  { email: "engineering.manager@acme.test", first_name: "Emma", last_name: "Engineer", role: "hiring_manager" },
  { email: "interviewer@acme.test", first_name: "Ian", last_name: "Interviewer", role: "interviewer" }
].each do |user_attrs|
  user = User.find_or_create_by!(
    organization: org,
    email: user_attrs[:email]
  ) do |u|
    u.first_name = user_attrs[:first_name]
    u.last_name = user_attrs[:last_name]
    u.password = "password123"
    u.password_confirmation = "password123"
    u.active = true
    u.confirmed_at = Time.current
  end

  # Assign role
  UserRole.find_or_create_by!(user: user, role: roles[user_attrs[:role]]) do |ur|
    ur.granted_at = Time.current
  end

  users[user_attrs[:role]] ||= []
  users[user_attrs[:role]] << user
  puts "  Created user: #{user.email} (#{user_attrs[:role]})"
end

# =============================================================================
# Departments
# =============================================================================
puts "Creating departments..."

departments = {}

[
  { name: "Engineering", code: "ENG" },
  { name: "Product", code: "PROD" },
  { name: "Design", code: "DES" },
  { name: "Sales", code: "SALES" },
  { name: "Marketing", code: "MKT" },
  { name: "Operations", code: "OPS" },
  { name: "Human Resources", code: "HR" }
].each do |dept_attrs|
  departments[dept_attrs[:code]] = Department.find_or_create_by!(
    organization: org,
    code: dept_attrs[:code]
  ) do |d|
    d.name = dept_attrs[:name]
    d.position = 0
  end
  puts "  Created department: #{dept_attrs[:name]}"
end

# =============================================================================
# Stages
# =============================================================================
puts "Creating pipeline stages..."

stages = {}

[
  { name: "Applied", stage_type: "applied", position: 0, color: "#6B7280" },
  { name: "Screening", stage_type: "screening", position: 1, color: "#3B82F6" },
  { name: "Phone Interview", stage_type: "interview", position: 2, color: "#8B5CF6" },
  { name: "Technical Interview", stage_type: "interview", position: 3, color: "#8B5CF6" },
  { name: "Onsite Interview", stage_type: "interview", position: 4, color: "#8B5CF6" },
  { name: "Offer", stage_type: "offer", position: 5, color: "#F59E0B" },
  { name: "Hired", stage_type: "hired", position: 6, is_terminal: true, color: "#10B981" },
  { name: "Rejected", stage_type: "rejected", position: 7, is_terminal: true, color: "#EF4444" }
].each do |stage_attrs|
  stages[stage_attrs[:name]] = Stage.find_or_create_by!(
    organization: org,
    name: stage_attrs[:name]
  ) do |s|
    s.stage_type = stage_attrs[:stage_type]
    s.position = stage_attrs[:position]
    s.is_terminal = stage_attrs[:is_terminal] || false
    s.is_default = true
    s.color = stage_attrs[:color]
  end
  puts "  Created stage: #{stage_attrs[:name]}"
end

# =============================================================================
# Rejection Reasons
# =============================================================================
puts "Creating rejection reasons..."

[
  { name: "Does not meet minimum qualifications", category: "not_qualified" },
  { name: "Insufficient experience", category: "not_qualified" },
  { name: "Missing required skills", category: "not_qualified" },
  { name: "Position filled", category: "timing" },
  { name: "Position closed", category: "timing" },
  { name: "Salary expectations too high", category: "compensation" },
  { name: "Benefits requirements not met", category: "compensation" },
  { name: "Not a culture fit", category: "culture_fit", requires_notes: true },
  { name: "Candidate withdrew", category: "withdrew" },
  { name: "Candidate unresponsive", category: "withdrew" },
  { name: "Other", category: "other", requires_notes: true }
].each_with_index do |reason_attrs, index|
  RejectionReason.find_or_create_by!(
    organization: org,
    name: reason_attrs[:name]
  ) do |r|
    r.category = reason_attrs[:category]
    r.requires_notes = reason_attrs[:requires_notes] || false
    r.active = true
    r.position = index
  end
  puts "  Created rejection reason: #{reason_attrs[:name]}"
end

# =============================================================================
# Jobs
# =============================================================================
puts "Creating jobs..."

jobs = []

job_data = [
  {
    title: "Senior Software Engineer",
    department: "ENG",
    status: "open",
    location: "San Francisco, CA",
    location_type: "hybrid",
    employment_type: "full_time",
    description: "We're looking for a Senior Software Engineer to join our growing team.",
    requirements: "5+ years of experience with Ruby on Rails or similar frameworks.",
    salary_min: 150_000_00,
    salary_max: 200_000_00
  },
  {
    title: "Product Manager",
    department: "PROD",
    status: "open",
    location: "Remote",
    location_type: "remote",
    employment_type: "full_time",
    description: "Join our product team to define and deliver features that delight customers.",
    requirements: "3+ years of product management experience in B2B SaaS."
  },
  {
    title: "UX Designer",
    department: "DES",
    status: "open",
    location: "New York, NY",
    location_type: "onsite",
    employment_type: "full_time",
    description: "We're seeking a talented UX Designer to create intuitive user experiences.",
    requirements: "Portfolio demonstrating user-centered design process."
  },
  {
    title: "Account Executive",
    department: "SALES",
    status: "open",
    location: "Chicago, IL",
    location_type: "hybrid",
    employment_type: "full_time",
    description: "Drive revenue growth by closing enterprise deals.",
    requirements: "5+ years of B2B software sales experience."
  },
  {
    title: "Marketing Manager",
    department: "MKT",
    status: "draft",
    location: "San Francisco, CA",
    location_type: "hybrid",
    employment_type: "full_time",
    description: "Lead our demand generation and content marketing efforts.",
    requirements: "Experience with marketing automation and analytics."
  },
  {
    title: "Junior Developer",
    department: "ENG",
    status: "closed",
    location: "Remote",
    location_type: "remote",
    employment_type: "full_time",
    description: "Entry-level position for recent graduates.",
    requirements: "CS degree or equivalent bootcamp experience."
  }
]

job_data.each do |job_attrs|
  job = Job.find_or_create_by!(
    organization: org,
    title: job_attrs[:title],
    department: departments[job_attrs[:department]]
  ) do |j|
    j.description = job_attrs[:description]
    j.requirements = job_attrs[:requirements]
    j.location = job_attrs[:location]
    j.location_type = job_attrs[:location_type]
    j.employment_type = job_attrs[:employment_type]
    j.status = job_attrs[:status]
    j.salary_min = job_attrs[:salary_min]
    j.salary_max = job_attrs[:salary_max]
    j.salary_currency = "USD"
    j.headcount = 1
    j.hiring_manager = users["hiring_manager"].first
    j.recruiter = users["recruiter"].first
    j.opened_at = Time.current if job_attrs[:status] == "open"
    j.closed_at = 1.week.ago if job_attrs[:status] == "closed"
  end
  jobs << job
  puts "  Created job: #{job.title} (#{job.status})"
end

# =============================================================================
# Candidates
# =============================================================================
puts "Creating candidates..."

candidates = []

candidate_data = [
  { first_name: "Sarah", last_name: "Chen", email: "sarah.chen@example.com", location: "San Francisco, CA" },
  { first_name: "Michael", last_name: "Johnson", email: "mjohnson@example.com", location: "Seattle, WA" },
  { first_name: "Emily", last_name: "Williams", email: "emily.w@example.com", location: "Austin, TX" },
  { first_name: "David", last_name: "Brown", email: "dbrown@example.com", location: "New York, NY" },
  { first_name: "Jennifer", last_name: "Davis", email: "jdavis@example.com", location: "Boston, MA" },
  { first_name: "Robert", last_name: "Miller", email: "rmiller@example.com", location: "Denver, CO" },
  { first_name: "Lisa", last_name: "Garcia", email: "lgarcia@example.com", location: "Los Angeles, CA" },
  { first_name: "James", last_name: "Wilson", email: "jwilson@example.com", location: "Chicago, IL" },
  { first_name: "Maria", last_name: "Martinez", email: "mmartinez@example.com", location: "Miami, FL" },
  { first_name: "Thomas", last_name: "Anderson", email: "tanderson@example.com", location: "Portland, OR" },
  { first_name: "Amanda", last_name: "Taylor", email: "ataylor@example.com", location: "San Diego, CA" },
  { first_name: "Christopher", last_name: "Thomas", email: "cthomas@example.com", location: "Phoenix, AZ" },
  { first_name: "Jessica", last_name: "Jackson", email: "jjackson@example.com", location: "Philadelphia, PA" },
  { first_name: "Daniel", last_name: "White", email: "dwhite@example.com", location: "Detroit, MI" },
  { first_name: "Ashley", last_name: "Harris", email: "aharris@example.com", location: "Atlanta, GA" }
]

candidate_data.each do |cand_attrs|
  candidate = Candidate.find_or_create_by!(
    organization: org,
    email: cand_attrs[:email]
  ) do |c|
    c.first_name = cand_attrs[:first_name]
    c.last_name = cand_attrs[:last_name]
    c.location = cand_attrs[:location]
    c.phone = "555-#{rand(100..999)}-#{rand(1000..9999)}"
  end
  candidates << candidate
  puts "  Created candidate: #{candidate.first_name} #{candidate.last_name}"
end

# =============================================================================
# Applications
# =============================================================================
puts "Creating applications..."

# Distribute candidates across open jobs
open_jobs = jobs.select { |j| j.status == "open" }
source_types = %w[career_site job_board referral agency direct linkedin other]

candidates.each_with_index do |candidate, index|
  job = open_jobs[index % open_jobs.length]
  stage = stages.values.reject(&:is_terminal).sample

  application = Application.find_or_create_by!(
    organization: org,
    job: job,
    candidate: candidate
  ) do |a|
    a.current_stage = stage
    a.status = "new"
    a.source_type = source_types.sample
    a.applied_at = rand(1..30).days.ago
    a.last_activity_at = rand(0..7).days.ago
    a.rating = [nil, 1, 2, 3, 4, 5].sample
    a.starred = rand < 0.2
  end
  puts "  Created application: #{candidate.first_name} -> #{job.title} (#{stage.name})"
end

# =============================================================================
# Summary
# =============================================================================
puts ""
puts "=" * 60
puts "Seed complete!"
puts "=" * 60
puts ""
puts "Created:"
puts "  - 1 Organization: #{org.name}"
puts "  - #{Role.where(organization: org).count} Roles"
puts "  - #{User.where(organization: org).count} Users"
puts "  - #{Department.where(organization: org).count} Departments"
puts "  - #{Stage.where(organization: org).count} Pipeline Stages"
puts "  - #{RejectionReason.where(organization: org).count} Rejection Reasons"
puts "  - #{Job.where(organization: org).count} Jobs"
puts "  - #{Candidate.where(organization: org).count} Candidates"
puts "  - #{Application.where(organization: org).count} Applications"
puts ""
puts "Login credentials (once auth is implemented):"
puts "  Admin:           admin@acme.test"
puts "  Recruiter:       recruiter@acme.test"
puts "  Hiring Manager:  hiring.manager@acme.test"
puts "  Interviewer:     interviewer@acme.test"
puts ""
