# frozen_string_literal: true

# SA-06: Interview - Interview participants (interviewers, shadows, etc.)
class CreateInterviewParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :interview_participants do |t|
      t.references :interview, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # Role in the interview
      t.string :role, null: false, default: "interviewer" # lead, interviewer, shadow, note_taker

      # Response status
      t.string :status, null: false, default: "pending" # pending, accepted, declined, tentative
      t.datetime :responded_at

      # Feedback tracking
      t.boolean :feedback_submitted, null: false, default: false
      t.datetime :feedback_submitted_at

      t.timestamps
    end

    add_index :interview_participants, [:interview_id, :user_id], unique: true
    add_index :interview_participants, [:interview_id, :role]
    add_index :interview_participants, [:user_id, :status]
    add_index :interview_participants, [:user_id, :feedback_submitted]
  end
end
