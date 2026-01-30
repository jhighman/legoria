# frozen_string_literal: true
# Rich narrative scenario data for Jack's lesson
# Run: bin/rails runner script/build_rich_scenario.rb

org = Organization.first
stages = Stage.all.index_by(&:name)
users = User.all.index_by(&:email)

rachel = users["recruiter@acme.test"]
henry = users["hiring.manager@acme.test"]
emma = users["engineering.manager@acme.test"]
ian = users["interviewer@acme.test"]
alice = users["admin@acme.test"]

# Helper to create interviews bypassing validation
def create_interview!(attrs)
  i = Interview.new(attrs)
  i.save!(validate: false)
  i
end

def create_offer!(attrs)
  o = Offer.new(attrs)
  o.save!(validate: false)
  o
end

# ============================================================
# NARRATIVE 1: Sarah Chen - Full Pipeline to Hire (Happy Path)
# Applied -> Screening -> Phone -> Technical -> Onsite -> Offer -> Hired
# ============================================================
puts "Building Narrative 1: Sarah Chen - Full Hire Pipeline..."

sarah_app = Application.find_by(candidate: Candidate.find_by(first_name: "Sarah"))
sarah_app.update_columns(applied_at: 30.days.ago, last_activity_at: 2.days.ago, status: "hired",
                         current_stage_id: stages["Hired"].id, hired_at: 2.days.ago,
                         rating: 5, starred: true, source_type: "referral")

[
  { from: "Applied", to: "Screening", moved_by: rachel, days_ago: 28, notes: "Resume looks strong. 7 years Rails experience. Referred by CTO." },
  { from: "Screening", to: "Phone Interview", moved_by: rachel, days_ago: 25, notes: "Passed initial screening. Strong distributed systems background." },
  { from: "Phone Interview", to: "Technical Interview", moved_by: rachel, days_ago: 20, notes: "Phone screen excellent. Articulate, structured problem-solving." },
  { from: "Technical Interview", to: "Onsite Interview", moved_by: henry, days_ago: 14, notes: "Top 10% coding assessment. Deep Rails and system design knowledge." },
  { from: "Onsite Interview", to: "Offer", moved_by: henry, days_ago: 7, notes: "Team unanimously recommends. Culture fit is strong." },
  { from: "Offer", to: "Hired", moved_by: alice, days_ago: 2, notes: "Offer accepted! Start date Feb 15." }
].each do |t|
  StageTransition.create!(
    application: sarah_app,
    from_stage: stages[t[:from]],
    to_stage: stages[t[:to]],
    moved_by: t[:moved_by],
    notes: t[:notes],
    created_at: t[:days_ago].days.ago
  )
end

create_interview!(
  organization: org, application: sarah_app, job: sarah_app.job,
  scheduled_by: rachel, interview_type: "phone_screen", status: "completed",
  title: "Phone Screen - Sarah Chen", scheduled_at: 25.days.ago,
  duration_minutes: 30, timezone: "America/New_York", completed_at: 25.days.ago
)

create_interview!(
  organization: org, application: sarah_app, job: sarah_app.job,
  scheduled_by: rachel, interview_type: "technical", status: "completed",
  title: "Technical Interview - Sarah Chen", scheduled_at: 20.days.ago,
  duration_minutes: 60, timezone: "America/New_York", location: "Zoom",
  video_meeting_url: "https://zoom.us/j/123456789", completed_at: 20.days.ago
)

create_interview!(
  organization: org, application: sarah_app, job: sarah_app.job,
  scheduled_by: rachel, interview_type: "onsite", status: "completed",
  title: "Onsite Interview - Sarah Chen", scheduled_at: 14.days.ago,
  duration_minutes: 180, timezone: "America/New_York",
  location: "SF Office - Room 4B", completed_at: 14.days.ago
)

HiringDecision.create!(
  organization: org, application: sarah_app, decided_by: henry, approved_by: alice,
  decision: "hire", status: "approved",
  rationale: "Strong technical skills, excellent culture fit, 7 years relevant experience. Unanimous team recommendation.",
  proposed_salary: 175000, proposed_salary_currency: "USD",
  proposed_start_date: Date.new(2026, 2, 15),
  decided_at: 8.days.ago, approved_at: 7.days.ago
)

create_offer!(
  organization: org, application: sarah_app, created_by: rachel,
  title: "Senior Software Engineer", status: "accepted",
  salary: 175000, salary_period: "annual", currency: "USD",
  signing_bonus: 15000, employment_type: "full_time",
  proposed_start_date: Date.new(2026, 2, 15),
  work_location: "San Francisco, CA (Hybrid)", department: "Engineering",
  sent_at: 7.days.ago, responded_at: 5.days.ago, response: "accepted"
)

CandidateNote.create!(candidate: sarah_app.candidate, user: rachel,
  content: "Sarah was referred by our CTO from a previous company. Very strong Rails background. Currently at Stripe.",
  visibility: "team", pinned: true, created_at: 30.days.ago)
CandidateNote.create!(candidate: sarah_app.candidate, user: henry,
  content: "Met Sarah at the onsite. Sharp, collaborative, asked great questions about our architecture. She would level up the whole team.",
  visibility: "team", created_at: 14.days.ago)
CandidateNote.create!(candidate: sarah_app.candidate, user: ian,
  content: "Paired with Sarah on a refactoring exercise. She thinks in systems, not just code. Strong hire.",
  visibility: "team", created_at: 14.days.ago)

["Ruby on Rails", "PostgreSQL", "Redis", "Docker", "AWS", "GraphQL", "React", "System Design"].each do |skill|
  CandidateSkill.create!(organization: org, candidate: sarah_app.candidate,
    name: skill, normalized_name: skill.downcase.gsub(" ", "_"),
    category: "technical",
    proficiency_level: ["intermediate", "advanced", "expert"].sample,
    years_experience: rand(3..8), source: "self_reported")
end

puts "  ✓ Sarah Chen: Hired (6 transitions, 3 interviews, offer accepted)"

# ============================================================
# NARRATIVE 2: Michael Johnson - Rejected After Technical
# ============================================================
puts "Building Narrative 2: Michael Johnson - Rejected..."

michael_app = Application.find_by(candidate: Candidate.find_by(first_name: "Michael"))
michael_app.update_columns(applied_at: 25.days.ago, last_activity_at: 15.days.ago, status: "rejected",
                           current_stage_id: stages["Rejected"].id, rejected_at: 15.days.ago,
                           rejection_reason_id: RejectionReason.find_by(name: "Missing required skills").id,
                           rejection_notes: "Unable to implement basic tree traversal. Needs more experience before senior role.",
                           source_type: "job_board")

[
  { from: "Applied", to: "Screening", moved_by: rachel, days_ago: 23, notes: "Decent resume. 4 years experience." },
  { from: "Screening", to: "Phone Interview", moved_by: rachel, days_ago: 21, notes: "Passed screening. Some gaps in distributed systems." },
  { from: "Phone Interview", to: "Technical Interview", moved_by: rachel, days_ago: 18, notes: "Phone screen okay, not stellar. Worth a technical look." },
  { from: "Technical Interview", to: "Rejected", moved_by: henry, days_ago: 15, notes: "Could not complete coding challenge. Fundamental CS gaps." }
].each do |t|
  StageTransition.create!(application: michael_app, from_stage: stages[t[:from]], to_stage: stages[t[:to]],
    moved_by: t[:moved_by], notes: t[:notes], created_at: t[:days_ago].days.ago)
end

create_interview!(organization: org, application: michael_app, job: michael_app.job,
  scheduled_by: rachel, interview_type: "phone_screen", status: "completed",
  title: "Phone Screen - Michael Johnson", scheduled_at: 21.days.ago,
  duration_minutes: 30, timezone: "America/New_York", completed_at: 21.days.ago)

create_interview!(organization: org, application: michael_app, job: michael_app.job,
  scheduled_by: rachel, interview_type: "technical", status: "completed",
  title: "Technical Interview - Michael Johnson", scheduled_at: 18.days.ago,
  duration_minutes: 60, timezone: "America/New_York", completed_at: 18.days.ago)

HiringDecision.create!(organization: org, application: michael_app, decided_by: henry,
  decision: "reject", status: "approved",
  rationale: "Technical assessment revealed gaps in core CS fundamentals. Not ready for senior role. Could reconsider for mid-level in 6 months.",
  decided_at: 15.days.ago, approved_at: 15.days.ago)

CandidateNote.create!(candidate: michael_app.candidate, user: rachel,
  content: "Michael was friendly and communicative but struggled on the technical assessment. Henry thinks he could be a fit for a mid-level role in the future.",
  visibility: "team", created_at: 15.days.ago)

puts "  ✓ Michael Johnson: Rejected (4 transitions, 2 interviews, decision documented)"

# ============================================================
# NARRATIVE 3: Jennifer Davis - In Progress (Hot Candidate)
# Applied -> Screening -> Phone -> Technical (scheduled tomorrow)
# ============================================================
puts "Building Narrative 3: Jennifer Davis - In Progress..."

jennifer_app = Application.find_by(candidate: Candidate.find_by(first_name: "Jennifer"))
jennifer_app.update_columns(applied_at: 15.days.ago, last_activity_at: 3.days.ago, status: "new",
                            current_stage_id: stages["Technical Interview"].id,
                            rating: 4, starred: true, source_type: "direct")

[
  { from: "Applied", to: "Screening", moved_by: rachel, days_ago: 13, notes: "Strong resume. MIT CS degree. Currently at Google." },
  { from: "Screening", to: "Phone Interview", moved_by: rachel, days_ago: 10, notes: "Impressive background. Fast-tracked." },
  { from: "Phone Interview", to: "Technical Interview", moved_by: rachel, days_ago: 5, notes: "Excellent phone screen. Articulate about system design trade-offs." }
].each do |t|
  StageTransition.create!(application: jennifer_app, from_stage: stages[t[:from]], to_stage: stages[t[:to]],
    moved_by: t[:moved_by], notes: t[:notes], created_at: t[:days_ago].days.ago)
end

create_interview!(organization: org, application: jennifer_app, job: jennifer_app.job,
  scheduled_by: rachel, interview_type: "phone_screen", status: "completed",
  title: "Phone Screen - Jennifer Davis", scheduled_at: 10.days.ago,
  duration_minutes: 30, timezone: "America/New_York", completed_at: 10.days.ago)

create_interview!(organization: org, application: jennifer_app, job: jennifer_app.job,
  scheduled_by: rachel, interview_type: "technical", status: "scheduled",
  title: "Technical Interview - Jennifer Davis", scheduled_at: 1.day.from_now,
  duration_minutes: 60, timezone: "America/New_York", location: "Zoom",
  video_meeting_url: "https://zoom.us/j/987654321")

CandidateNote.create!(candidate: jennifer_app.candidate, user: rachel,
  content: "Jennifer is a top candidate. Currently at Google, looking to move to a smaller company. Has competing offer from Stripe. We need to move fast.",
  visibility: "team", pinned: true, created_at: 10.days.ago)

["Ruby on Rails", "Go", "Kubernetes", "PostgreSQL", "System Design", "Distributed Systems"].each do |skill|
  CandidateSkill.create!(organization: org, candidate: jennifer_app.candidate,
    name: skill, normalized_name: skill.downcase.gsub(" ", "_"),
    category: "technical",
    proficiency_level: "advanced", years_experience: rand(4..7), source: "self_reported")
end

puts "  ✓ Jennifer Davis: In progress (3 transitions, 2 interviews, skills tagged)"

# ============================================================
# NARRATIVE 4: James Wilson - Just Applied Yesterday
# Fresh applicant, no activity yet
# ============================================================
puts "Building Narrative 4: James Wilson - Fresh Applicant..."

james_app = Application.find_by(candidate: Candidate.find_by(first_name: "James"))
james_app.update_columns(applied_at: 1.day.ago, last_activity_at: 1.day.ago,
                         current_stage_id: stages["Applied"].id, status: "new",
                         source_type: "linkedin")

puts "  ✓ James Wilson: Fresh applicant (no transitions yet)"

# ============================================================
# NARRATIVE 5: David Brown - Withdrawn by Candidate
# Got to Phone Interview, then withdrew for Salesforce offer
# ============================================================
puts "Building Narrative 5: David Brown - Withdrawn..."

david_app = Application.find_by(candidate: Candidate.find_by(first_name: "David"))
david_app.update_columns(applied_at: 20.days.ago, last_activity_at: 8.days.ago, status: "withdrawn",
                         current_stage_id: stages["Phone Interview"].id,
                         withdrawn_at: 8.days.ago, source_type: "career_site")

[
  { from: "Applied", to: "Screening", moved_by: rachel, days_ago: 18, notes: "Good profile for Account Executive." },
  { from: "Screening", to: "Phone Interview", moved_by: rachel, days_ago: 15, notes: "Sales background checks out. Scheduled phone screen." }
].each do |t|
  StageTransition.create!(application: david_app, from_stage: stages[t[:from]], to_stage: stages[t[:to]],
    moved_by: t[:moved_by], notes: t[:notes], created_at: t[:days_ago].days.ago)
end

create_interview!(organization: org, application: david_app, job: david_app.job,
  scheduled_by: rachel, interview_type: "phone_screen", status: "cancelled",
  title: "Phone Screen - David Brown", scheduled_at: 12.days.ago,
  duration_minutes: 30, timezone: "America/New_York",
  cancelled_at: 8.days.ago, cancellation_reason: "Candidate withdrew - accepted offer at Salesforce")

CandidateNote.create!(candidate: david_app.candidate, user: rachel,
  content: "David called to withdraw. Accepted an offer at Salesforce. Said he might be interested in future openings. Adding to talent pool.",
  visibility: "team", created_at: 8.days.ago)

puts "  ✓ David Brown: Withdrawn (2 transitions, 1 cancelled interview)"

# ============================================================
# NARRATIVE 6: Emily Williams - Slow Mover (Screening)
# Applied 3 weeks ago, still in screening. Shows pipeline bottleneck.
# ============================================================
puts "Building Narrative 6: Emily Williams - Slow Mover..."

emily_app = Application.find_by(candidate: Candidate.find_by(first_name: "Emily"))
emily_app.update_columns(applied_at: 22.days.ago, last_activity_at: 19.days.ago, status: "new",
                         current_stage_id: stages["Screening"].id, source_type: "job_board")

StageTransition.create!(application: emily_app, from_stage: stages["Applied"], to_stage: stages["Screening"],
  moved_by: rachel, notes: "UX portfolio looks interesting. Need to schedule screening call.",
  created_at: 19.days.ago)

CandidateNote.create!(candidate: emily_app.candidate, user: rachel,
  content: "Emily's portfolio is strong but I've been swamped with the Sr. Engineer pipeline. Need to get back to her ASAP.",
  visibility: "private", created_at: 10.days.ago)

puts "  ✓ Emily Williams: Stuck in screening for 19 days (bottleneck example)"

# ============================================================
# NARRATIVE 7: Robert Miller - Multiple Interviews, Strong Candidate
# Product Manager pipeline - Phone -> Technical -> almost ready for onsite
# ============================================================
puts "Building Narrative 7: Robert Miller - Strong PM Candidate..."

robert_app = Application.find_by(candidate: Candidate.find_by(first_name: "Robert"))
robert_app.update_columns(applied_at: 18.days.ago, last_activity_at: 4.days.ago, status: "new",
                          current_stage_id: stages["Technical Interview"].id,
                          rating: 4, starred: true, source_type: "referral")

[
  { from: "Applied", to: "Screening", moved_by: rachel, days_ago: 16, notes: "Product Manager from Figma. Strong background." },
  { from: "Screening", to: "Phone Interview", moved_by: rachel, days_ago: 12, notes: "Great screening conversation. Clear product thinking." },
  { from: "Phone Interview", to: "Technical Interview", moved_by: rachel, days_ago: 7, notes: "Phone screen was impressive. Clear frameworks for prioritization." }
].each do |t|
  StageTransition.create!(application: robert_app, from_stage: stages[t[:from]], to_stage: stages[t[:to]],
    moved_by: t[:moved_by], notes: t[:notes], created_at: t[:days_ago].days.ago)
end

create_interview!(organization: org, application: robert_app, job: robert_app.job,
  scheduled_by: rachel, interview_type: "phone_screen", status: "completed",
  title: "Phone Screen - Robert Miller", scheduled_at: 12.days.ago,
  duration_minutes: 45, timezone: "America/New_York", completed_at: 12.days.ago)

create_interview!(organization: org, application: robert_app, job: robert_app.job,
  scheduled_by: rachel, interview_type: "technical", status: "completed",
  title: "Product Case Study - Robert Miller", scheduled_at: 4.days.ago,
  duration_minutes: 90, timezone: "America/New_York",
  location: "Zoom", completed_at: 4.days.ago)

CandidateNote.create!(candidate: robert_app.candidate, user: henry,
  content: "Robert crushed the product case study. His framework for evaluating build vs buy was impressive. Ready for onsite.",
  visibility: "team", pinned: true, created_at: 4.days.ago)

["Product Strategy", "User Research", "SQL", "A/B Testing", "Roadmap Planning", "Stakeholder Management"].each do |skill|
  CandidateSkill.create!(organization: org, candidate: robert_app.candidate,
    name: skill, normalized_name: skill.downcase.gsub(" ", "_"),
    category: "domain",
    proficiency_level: "advanced", years_experience: rand(4..8), source: "self_reported")
end

puts "  ✓ Robert Miller: Technical done, ready for onsite (3 transitions, 2 interviews)"

# ============================================================
# TALENT POOLS
# ============================================================
puts "Building Talent Pools..."

pool = TalentPool.create!(organization: org, name: "Future Candidates",
  description: "Strong candidates who didn't work out this time but should be revisited",
  pool_type: "manual", owner: rachel)

TalentPoolMember.create!(talent_pool: pool,
  candidate: Candidate.find_by(first_name: "Michael"),
  added_by: rachel, notes: "Revisit for mid-level role in 6 months")
TalentPoolMember.create!(talent_pool: pool,
  candidate: Candidate.find_by(first_name: "David"),
  added_by: rachel, notes: "Withdrew for Salesforce. May circle back.")

eng_pool = TalentPool.create!(organization: org, name: "Engineering Pipeline",
  description: "Active engineering candidates across all roles",
  pool_type: "manual", owner: rachel)

["Sarah", "Jennifer", "Maria"].each do |name|
  TalentPoolMember.create!(talent_pool: eng_pool,
    candidate: Candidate.find_by(first_name: name),
    added_by: rachel, notes: "Senior engineering candidate")
end

puts "  ✓ 2 Talent Pools created"

# ============================================================
# SUMMARY
# ============================================================
puts ""
puts "=" * 60
puts "Rich scenario complete!"
puts "=" * 60
puts ""
puts "Narratives:"
puts "  1. Sarah Chen      → HIRED (full pipeline, 6 transitions, 3 interviews, offer)"
puts "  2. Michael Johnson  → REJECTED (technical fail, documented decision)"
puts "  3. Jennifer Davis   → IN PROGRESS (hot candidate, competing offer, tech tomorrow)"
puts "  4. James Wilson     → JUST APPLIED (fresh, no activity)"
puts "  5. David Brown      → WITHDRAWN (accepted Salesforce, added to talent pool)"
puts "  6. Emily Williams   → STUCK IN SCREENING (bottleneck, 19 days)"
puts "  7. Robert Miller    → STRONG PM (ready for onsite)"
puts ""
puts "Data totals:"
puts "  StageTransitions: #{StageTransition.count}"
puts "  Interviews: #{Interview.count}"
puts "  HiringDecisions: #{HiringDecision.count}"
puts "  Offers: #{Offer.count}"
puts "  CandidateNotes: #{CandidateNote.count}"
puts "  CandidateSkills: #{CandidateSkill.count}"
puts "  TalentPools: #{TalentPool.count}"
puts "  TalentPoolMembers: #{TalentPoolMember.count}"
