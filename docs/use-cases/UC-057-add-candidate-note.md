# UC-057: Add Candidate Note

## Metadata

| Attribute | Value |
|-----------|-------|
| **ID** | UC-057 |
| **Name** | Add Candidate Note |
| **Functional Area** | Candidate Management |
| **Primary Actor** | Recruiter (ACT-02) |
| **Priority** | P1 |
| **Complexity** | Low |
| **Status** | Draft |

## Description

A recruiter or hiring team member adds an internal note to a candidate's profile. Notes can have different visibility levels (private, team, or all) and can optionally be pinned for prominence. Notes are used to document interactions, assessments, and important information about candidates.

## Actors

| Actor | Role in Use Case |
|-------|------------------|
| Recruiter (ACT-02) | Adds and manages notes on candidates |
| Hiring Manager (ACT-03) | Adds notes on candidates for their jobs |
| Interviewer (ACT-04) | Adds notes after interactions |

## Preconditions

- [ ] User is authenticated and has access to candidate
- [ ] Candidate record exists and is not deleted
- [ ] User has permission to add notes

## Postconditions

### Success
- [ ] CandidateNote record created
- [ ] Note visible to appropriate users based on visibility
- [ ] Audit log entry created
- [ ] Candidate last_activity_at updated

### Failure
- [ ] No note created
- [ ] User shown validation errors

## Triggers

- User clicks "Add Note" on candidate profile
- User clicks "+" in notes section
- User completes quick note in timeline view

## Basic Flow

```mermaid
sequenceDiagram
    actor REC as Recruiter
    participant UI as Notes Panel
    participant NC as NotesController
    participant Note as CandidateNote Model
    participant Cand as Candidate Model
    participant AL as AuditLog
    participant DB as Database

    REC->>UI: Click "Add Note"
    UI->>UI: Display note editor
    REC->>UI: Enter note content
    REC->>UI: Select visibility
    REC->>UI: Click "Save Note"
    UI->>NC: POST /candidates/:id/notes
    NC->>NC: Authorize (note permission)
    NC->>Note: create(params)
    Note->>Note: validate
    Note->>DB: INSERT INTO candidate_notes
    DB-->>Note: note_id
    NC->>Cand: touch(:last_activity_at)
    Cand->>DB: UPDATE candidates
    NC->>AL: log_note_added
    AL->>DB: INSERT INTO audit_logs
    NC-->>UI: Return created note
    UI-->>REC: Display new note
```

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 1 | Recruiter | Clicks "Add Note" | Note editor displayed |
| 2 | Recruiter | Enters note content | Content captured |
| 3 | Recruiter | Selects visibility level | Visibility set |
| 4 | Recruiter | Optionally pins note | Pin flag set |
| 5 | Recruiter | Clicks "Save Note" | System validates |
| 6 | System | Validates note content | Content not empty |
| 7 | System | Creates CandidateNote record | Note saved |
| 8 | System | Updates candidate activity timestamp | Activity recorded |
| 9 | System | Creates audit log entry | Audit record saved |
| 10 | System | Displays note in timeline | Note visible |

## Alternative Flows

### AF-1: Quick Note from Timeline

**Trigger:** User adds note directly from activity timeline

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 1a | Recruiter | Types in quick note field | Content entered |
| 2a | Recruiter | Presses Enter or clicks Post | Default visibility applied |
| 3a | System | Creates note with team visibility | Note saved |

**Resumption:** Continues at step 8

### AF-2: Edit Existing Note

**Trigger:** User clicks edit on their own note

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 1a | Recruiter | Clicks "Edit" on own note | Note becomes editable |
| 2a | Recruiter | Modifies content | Changes captured |
| 3a | Recruiter | Clicks "Save" | Note updated |
| 4a | System | Records edit history | Edit timestamp saved |

**Resumption:** Use case ends

### AF-3: Delete Note

**Trigger:** User deletes their own note

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 1a | Recruiter | Clicks "Delete" on own note | Confirmation dialog |
| 2a | Recruiter | Confirms deletion | Note soft-deleted |
| 3a | System | Logs deletion | Audit record created |

**Resumption:** Use case ends

### AF-4: Pin/Unpin Note

**Trigger:** User pins or unpins a note

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 1a | Recruiter | Clicks pin icon on note | Note pinned/unpinned |
| 2a | System | Updates pin status | Note reordered |

**Resumption:** Note moves to top (if pinned) or back to timeline

## Exception Flows

### EF-1: Empty Note Content

**Trigger:** User tries to save empty note

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 6.1 | System | Detects empty content | Shows error message |
| 6.2 | Recruiter | Enters content | Content captured |
| 6.3 | Recruiter | Resubmits | System re-validates |

**Resolution:** Returns to step 6

### EF-2: Note Content Too Long

**Trigger:** Note exceeds maximum length

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 6.1 | System | Detects length exceeded | Shows character count error |
| 6.2 | Recruiter | Shortens content | Content within limit |
| 6.3 | Recruiter | Resubmits | System re-validates |

**Resolution:** Returns to step 6

### EF-3: Edit Permission Denied

**Trigger:** User tries to edit another user's note

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 1.1 | System | Checks note ownership | Different author |
| 1.2 | System | Hides edit option | Action not available |

**Resolution:** User cannot edit others' notes

## Business Rules

| ID | Rule | Description |
|----|------|-------------|
| BR-057.1 | Required Content | Note content cannot be empty |
| BR-057.2 | Max Length | Note content max 10,000 characters |
| BR-057.3 | Visibility Levels | private (author only), team (job team), all (everyone with access) |
| BR-057.4 | Edit Own Only | Users can only edit their own notes |
| BR-057.5 | Delete Own Only | Users can only delete their own notes |
| BR-057.6 | Pinned Limit | Max 3 pinned notes per candidate |
| BR-057.7 | Activity Update | Adding note updates candidate last_activity_at |

## Data Requirements

### Input Data

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| candidate_id | integer | Yes | Must exist |
| content | text | Yes | 1-10,000 chars |
| visibility | enum | Yes | private, team, all |
| pinned | boolean | No | Default false |

### Output Data

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Note identifier |
| user_id | integer | Author user ID |
| created_at | datetime | Creation timestamp |
| updated_at | datetime | Last edit timestamp |

## Database Transactions

### Tables Affected

| Table | Operation | Conditions |
|-------|-----------|------------|
| candidate_notes | CREATE | Always |
| candidates | UPDATE | Update last_activity_at |
| audit_logs | CREATE | Always |

### Transaction Detail

```sql
-- Add Candidate Note Transaction
BEGIN TRANSACTION;

-- Step 1: Verify candidate exists and user has access
SELECT id FROM candidates
WHERE id = @candidate_id
  AND organization_id = @organization_id
  AND discarded_at IS NULL;

-- Step 2: Create note record
INSERT INTO candidate_notes (
    candidate_id,
    user_id,
    content,
    visibility,
    pinned,
    created_at,
    updated_at
) VALUES (
    @candidate_id,
    @current_user_id,
    @content,
    @visibility,
    @pinned,
    NOW(),
    NOW()
);

SET @note_id = LAST_INSERT_ID();

-- Step 3: Update candidate activity timestamp
UPDATE candidates
SET last_activity_at = NOW(),
    updated_at = NOW()
WHERE id = @candidate_id;

-- Step 4: Create audit log entry
INSERT INTO audit_logs (
    organization_id,
    user_id,
    action,
    auditable_type,
    auditable_id,
    metadata,
    ip_address,
    user_agent,
    created_at
) VALUES (
    @organization_id,
    @current_user_id,
    'candidate_note.created',
    'CandidateNote',
    @note_id,
    JSON_OBJECT(
        'candidate_id', @candidate_id,
        'visibility', @visibility,
        'content_length', LENGTH(@content)
    ),
    @ip_address,
    @user_agent,
    NOW()
);

COMMIT;
```

### Rollback Scenarios

| Scenario | Rollback Action |
|----------|-----------------|
| Validation failure | No transaction started |
| Candidate not found | Return error |
| Database error | Full rollback |

## UI/UX Requirements

### Screen/Component

- **Location:** Candidate profile, notes section
- **Entry Point:**
  - "Add Note" button
  - Quick note input in timeline
  - Right-click context menu
- **Key Elements:**
  - Note editor (rich text optional)
  - Visibility selector
  - Pin toggle
  - Character counter
  - Save/Cancel buttons

### Notes Panel Layout

```
+-------------------------------------------------------------+
| Notes                                           [+ Add Note] |
+-------------------------------------------------------------+
| Pinned Notes                                                 |
| +----------------------------------------------------------+ |
| | [Pin] Sarah Jones - Jan 20, 2026 at 2:30 PM              | |
| |       Team                                    [Edit] [x] | |
| | "Excellent communication skills demonstrated in phone     | |
| |  screen. Very articulate and professional. Recommend     | |
| |  moving forward with technical interview."               | |
| +----------------------------------------------------------+ |
|                                                              |
| Recent Notes                                                 |
| +----------------------------------------------------------+ |
| | Mike Chen - Jan 18, 2026 at 10:15 AM                     | |
| | Private                                       [Edit] [x] | |
| | "Salary expectation seems high for the role. Will need   | |
| |  to discuss compensation expectations."                  | |
| +----------------------------------------------------------+ |
| | Sarah Jones - Jan 15, 2026 at 4:45 PM                    | |
| | Team                                                     | |
| | "Initial sourcing call completed. Candidate is currently | |
| |  actively looking and available in 2 weeks."             | |
| +----------------------------------------------------------+ |
|                                                              |
| [Load More Notes...]                                         |
+-------------------------------------------------------------+
```

### Add Note Modal

```
+-------------------------------------------------------------+
| Add Note for John Smith                                      |
+-------------------------------------------------------------+
|                                                              |
| +----------------------------------------------------------+ |
| |                                                          | |
| | Write your note here...                                  | |
| |                                                          | |
| |                                                          | |
| +----------------------------------------------------------+ |
| 0 / 10,000 characters                                        |
|                                                              |
| Visibility                                                   |
| +----------------------------------------------------------+ |
| | (*) Team - Visible to hiring team for this candidate     | |
| | ( ) Private - Only visible to you                        | |
| | ( ) Everyone - Visible to all users with candidate access| |
| +----------------------------------------------------------+ |
|                                                              |
| [ ] Pin this note                                            |
|                                                              |
+-------------------------------------------------------------+
| [Cancel]                                      [Save Note]    |
+-------------------------------------------------------------+
```

## Non-Functional Requirements

| Requirement | Target |
|-------------|--------|
| Response Time | Save < 1s |
| Availability | 99.9% |
| Character Count | Real-time update |
| Autosave Draft | Every 30 seconds |

## Security Considerations

- [x] Authentication required
- [x] Authorization check: User must have candidate access
- [x] Visibility enforcement: Notes filtered by visibility
- [x] Edit/Delete: Only note author can modify
- [x] Audit logging: All note actions logged
- [x] No PII in notes: Policy, not technical control

## Related Use Cases

| Use Case | Relationship |
|----------|--------------|
| UC-050 Add Candidate Manually | May include initial notes |
| UC-054 Edit Candidate Profile | Alternative for structured info |
| UC-202 Add Interview Notes | Similar but interview-specific |

---

## Data Model References

> Cross-references to [DATA_MODEL.md](../DATA_MODEL.md) and [CRUD_MATRIX.md](../CRUD_MATRIX.md)

### Subject Areas

| Subject Area | ID | Relationship |
|--------------|-----|--------------|
| Candidate | SA-04 | Primary |
| Compliance & Audit | SA-09 | Reference |

### Entities CRUD

| Entity | C | R | U | D | Notes |
|--------|---|---|---|---|-------|
| CandidateNote | X | X | X | X | Full CRUD by author |
| Candidate | | X | X | | Activity timestamp updated |
| AuditLog | X | | | | Created for note actions |

**Legend:** C = Create, R = Read, U = Update, D = Delete

---

## Process Model References

> Cross-references to [PROCESS_MODEL.md](../PROCESS_MODEL.md) and [PROCESS_CRUD_MATRIX.md](../PROCESS_CRUD_MATRIX.md)

| Attribute | Value | Link |
|-----------|-------|------|
| **Elementary Business Process** | EP-0208: Add Candidate Note | [PROCESS_MODEL.md#ep-0208](../PROCESS_MODEL.md#bp-102-candidate-sourcing) |
| **Business Process** | BP-102: Candidate Sourcing | [PROCESS_MODEL.md#bp-102](../PROCESS_MODEL.md#bp-102-candidate-sourcing) |
| **Business Function** | BF-01: Talent Acquisition | [PROCESS_MODEL.md#bf-01](../PROCESS_MODEL.md#bf-01-talent-acquisition) |

### EBP Details

| Attribute | Value |
|-----------|-------|
| **Trigger** | User initiates note creation |
| **Input** | Note content, visibility level |
| **Output** | CandidateNote record |
| **Business Rules** | BR-057.1 through BR-057.7 (see Business Rules section) |

---

## Traceability Matrix

> Complete artifact mapping for requirements traceability

| Artifact Type | ID | Name | Link |
|---------------|-----|------|------|
| **Use Case** | UC-057 | Add Candidate Note | *(this document)* |
| **Elementary Process** | EP-0208 | Add Candidate Note | [PROCESS_MODEL.md](../PROCESS_MODEL.md#bp-102-candidate-sourcing) |
| **Business Process** | BP-102 | Candidate Sourcing | [PROCESS_MODEL.md](../PROCESS_MODEL.md#bp-102-candidate-sourcing) |
| **Business Function** | BF-01 | Talent Acquisition | [PROCESS_MODEL.md](../PROCESS_MODEL.md#bf-01-talent-acquisition) |
| **Primary Actor** | ACT-02 | Recruiter | [ACTORS.md](../ACTORS.md#act-02-recruiter) |
| **Subject Area (Primary)** | SA-04 | Candidate | [DATA_MODEL.md](../DATA_MODEL.md#sa-04-candidate) |
| **CRUD Matrix Row** | UC-057 | - | [CRUD_MATRIX.md](../CRUD_MATRIX.md#uc-057) |
| **Process CRUD Row** | EP-0208 | - | [PROCESS_CRUD_MATRIX.md](../PROCESS_CRUD_MATRIX.md#ep-0208) |

### Implementation Artifacts

| Artifact Type | Path/Reference | Status |
|---------------|----------------|--------|
| Controller | `app/controllers/admin/candidate_notes_controller.rb` | Planned |
| Model | `app/models/candidate_note.rb` | Planned |
| Policy | `app/policies/candidate_note_policy.rb` | Planned |
| View | `app/views/admin/candidate_notes/_form.html.erb` | Planned |
| Test | `test/controllers/admin/candidate_notes_controller_test.rb` | Planned |

---

## Open Questions

1. Should notes support @ mentions to notify team members?
2. Should notes support file attachments?
3. Should admins be able to edit/delete any note?
4. Should there be note templates for common scenarios?

## Change History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-01-25 | System | Initial draft |
