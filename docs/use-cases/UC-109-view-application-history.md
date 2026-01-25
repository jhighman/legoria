# UC-109: View Application History

## Metadata

| Attribute | Value |
|-----------|-------|
| **ID** | UC-109 |
| **Name** | View Application History |
| **Functional Area** | Application & Pipeline |
| **Primary Actor** | Recruiter (ACT-02) |
| **Priority** | P2 |
| **Complexity** | Low |
| **Status** | Draft |

## Description

A recruiter, hiring manager, or other authorized user views the complete timeline of an application, including all stage transitions, interviews, scorecards, offers, communications, notes, and system events. This chronological history provides full visibility into the candidate's journey through the hiring process and supports compliance audits, dispute resolution, and process improvement.

## Actors

| Actor | Role in Use Case |
|-------|------------------|
| Recruiter (ACT-02) | Views full application history |
| Hiring Manager (ACT-03) | Views history for their jobs |
| Compliance Officer (ACT-06) | Reviews history for audits |
| Interviewer (ACT-04) | May view limited history |

## Preconditions

- [ ] User is authenticated with appropriate role
- [ ] Application exists (active or terminal)
- [ ] User has permission to view this application

## Postconditions

### Success
- [ ] Complete timeline displayed
- [ ] Events sorted chronologically (newest first or oldest first)
- [ ] Filtering applied as requested
- [ ] Details expandable for each event

### Failure
- [ ] Error message displayed
- [ ] Partial data shown with retry option

## Triggers

- Click "History" or "Activity" tab on application detail
- Click timeline icon from pipeline card
- Navigate from audit log search
- Deep link from notification

## Basic Flow

```mermaid
sequenceDiagram
    actor REC as Recruiter
    participant AV as Application View
    participant HT as History Tab
    participant HC as HistoryController
    participant ST as StageTransition
    participant AL as AuditLog
    participant INT as Interview
    participant SC as Scorecard
    participant OFF as Offer
    participant DB as Database

    REC->>AV: Views application
    REC->>AV: Clicks "History" tab
    AV->>HT: Load history tab
    HT->>HC: GET /applications/:id/history
    HC->>HC: Authorize access

    par Parallel data loading
        HC->>ST: load stage_transitions
        ST->>DB: SELECT transitions
        and
        HC->>AL: load audit_logs
        AL->>DB: SELECT audit_logs
        and
        HC->>INT: load interviews
        INT->>DB: SELECT interviews
        and
        HC->>SC: load scorecards
        SC->>DB: SELECT scorecards
        and
        HC->>OFF: load offers
        OFF->>DB: SELECT offers
    end

    HC->>HC: Merge and sort by timestamp
    HC-->>HT: Render timeline
    HT-->>REC: Display activity history
```

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 1 | Recruiter | Views application detail page | Application info displayed |
| 2 | Recruiter | Clicks "History" or "Activity" tab | Tab becomes active |
| 3 | System | Requests history data | API call initiated |
| 4 | System | Loads stage transitions | All transitions retrieved |
| 5 | System | Loads audit log entries | Related audit events retrieved |
| 6 | System | Loads interviews | Interview records retrieved |
| 7 | System | Loads scorecards | Scorecard records retrieved |
| 8 | System | Loads offers | Offer records retrieved |
| 9 | System | Loads communications | Email/notification log retrieved |
| 10 | System | Merges all events | Unified timeline created |
| 11 | System | Sorts by timestamp | Chronological order |
| 12 | UI | Renders timeline | Visual activity feed |
| 13 | UI | Shows expandable details | Click to see more |

## Alternative Flows

### AF-1: Filter by Event Type

**Trigger:** User wants to see specific event types only

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 12a | Recruiter | Clicks filter dropdown | Filter options shown |
| 12b | Recruiter | Selects "Stage Changes Only" | Filter applied |
| 12c | System | Filters timeline | Only transitions shown |

**Resumption:** Display updates with filtered events

### AF-2: Expand Event Details

**Trigger:** User wants more information about an event

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 13a | Recruiter | Clicks on event | Event expands |
| 13b | System | Shows full details | Notes, metadata, linked items |
| 13c | Recruiter | Clicks linked item | Navigates to detail |

**Resumption:** User can continue browsing or navigate

### AF-3: View as Timeline vs. List

**Trigger:** User prefers different visualization

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 12a | Recruiter | Clicks "List View" toggle | View changes |
| 12b | System | Renders table format | Sortable columns |

**Resumption:** User continues with preferred view

### AF-4: View from Compliance Audit

**Trigger:** Compliance officer reviewing for audit

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 1a | Compliance | Accesses via audit search | Limited context |
| 4a | System | Loads all data sources | Extra compliance fields |
| 12a | System | Includes IP addresses | Compliance data shown |

**Resumption:** Enhanced audit view displayed

### AF-5: Candidate Views Own History

**Trigger:** Candidate checking status in portal

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 3a | Candidate | Views from portal | Limited view |
| 4a | System | Filters to public events | Internal notes hidden |
| 12a | UI | Shows candidate-appropriate | Simplified timeline |

**Resumption:** Candidate-safe view displayed

## Exception Flows

### EF-1: Application Not Found

**Trigger:** Application ID doesn't exist

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 3.1 | System | Cannot find application | 404 raised |
| 3.2 | UI | Shows not found | Error message |

**Resolution:** User navigates back

### EF-2: Access Denied

**Trigger:** User lacks permission for this application

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 3.1 | System | Authorization fails | 403 raised |
| 3.2 | UI | Shows access denied | Explains restriction |

**Resolution:** User contacts admin

### EF-3: Large History (Performance)

**Trigger:** Application has 500+ events

| Step | Actor | Action | System Response |
|------|-------|--------|-----------------|
| 10.1 | System | Detects large dataset | Count exceeds threshold |
| 10.2 | System | Paginates results | First 100 loaded |
| 12.1 | UI | Shows "Load More" | Infinite scroll enabled |

**Resolution:** User scrolls or filters to load more

## Business Rules

| ID | Rule | Description |
|----|------|-------------|
| BR-109.1 | Org Scoping | Only show events from user's organization |
| BR-109.2 | Permission Check | User must have view access to application |
| BR-109.3 | Internal Notes Hidden | Candidates cannot see internal notes |
| BR-109.4 | Chronological Order | Default sort is newest first |
| BR-109.5 | Event Attribution | Each event shows who and when |
| BR-109.6 | Immutable Display | Historical events cannot be edited |
| BR-109.7 | Complete History | Include all event types for full picture |

## Data Requirements

### Input Data

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| application_id | integer | Yes | Must exist, user must have access |
| filter | string | No | Valid event type or 'all' |
| sort | string | No | 'asc' or 'desc' (default desc) |
| page | integer | No | For pagination |
| per_page | integer | No | Default 50, max 100 |

### Output Data

| Field | Type | Description |
|-------|------|-------------|
| events | array | Merged, sorted timeline events |
| total_count | integer | Total events matching filter |
| application | object | Basic application info |
| candidate | object | Candidate name and info |
| job | object | Job title and status |

### Event Object Structure

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique event identifier |
| event_type | string | Category of event |
| title | string | Brief description |
| description | text | Full detail |
| occurred_at | datetime | When event happened |
| actor | object | Who performed action |
| metadata | object | Additional event data |
| expandable | boolean | Has more details |
| linked_record | object | Associated record link |

## Database Transactions

### Tables Affected

| Table | Operation | Conditions |
|-------|-----------|------------|
| applications | READ | Base application data |
| stage_transitions | READ | All for application |
| audit_logs | READ | Filtered by application |
| interviews | READ | All for application |
| scorecards | READ | All for application |
| offers | READ | All for application |
| candidate_notes | READ | All for candidate+application |
| email_logs | READ | All for candidate+application |

### Query Detail

```sql
-- Unified History Query (pseudo-SQL for combined result)

-- Stage Transitions
SELECT
    'stage_transition' AS event_type,
    CONCAT('transition_', id) AS event_id,
    CONCAT('Moved to ', (SELECT name FROM stages WHERE id = to_stage_id)) AS title,
    notes AS description,
    created_at AS occurred_at,
    moved_by_id AS actor_id,
    (SELECT display_name FROM users WHERE id = moved_by_id) AS actor_name,
    JSON_OBJECT(
        'from_stage', (SELECT name FROM stages WHERE id = from_stage_id),
        'to_stage', (SELECT name FROM stages WHERE id = to_stage_id),
        'duration_hours', duration_hours
    ) AS metadata
FROM stage_transitions
WHERE application_id = @application_id

UNION ALL

-- Interviews
SELECT
    'interview' AS event_type,
    CONCAT('interview_', id) AS event_id,
    CONCAT(interview_type, ' Interview') AS title,
    CONCAT('With ', (SELECT GROUP_CONCAT(u.display_name) FROM interview_participants ip
                     JOIN users u ON u.id = ip.user_id
                     WHERE ip.interview_id = interviews.id)) AS description,
    scheduled_at AS occurred_at,
    created_by_id AS actor_id,
    (SELECT display_name FROM users WHERE id = created_by_id) AS actor_name,
    JSON_OBJECT(
        'status', status,
        'interview_type', interview_type,
        'duration_minutes', duration_minutes,
        'location', location
    ) AS metadata
FROM interviews
WHERE application_id = @application_id

UNION ALL

-- Scorecards
SELECT
    'scorecard' AS event_type,
    CONCAT('scorecard_', id) AS event_id,
    CONCAT('Scorecard submitted by ', (SELECT display_name FROM users WHERE id = interviewer_id)) AS title,
    CONCAT('Recommendation: ', recommendation) AS description,
    submitted_at AS occurred_at,
    interviewer_id AS actor_id,
    (SELECT display_name FROM users WHERE id = interviewer_id) AS actor_name,
    JSON_OBJECT(
        'recommendation', recommendation,
        'overall_rating', overall_rating,
        'interview_id', interview_id
    ) AS metadata
FROM scorecards
WHERE application_id = @application_id
  AND status = 'submitted'

UNION ALL

-- Offers
SELECT
    'offer' AS event_type,
    CONCAT('offer_', id) AS event_id,
    CONCAT('Offer ', status) AS title,
    '' AS description,
    updated_at AS occurred_at,
    created_by_id AS actor_id,
    (SELECT display_name FROM users WHERE id = created_by_id) AS actor_name,
    JSON_OBJECT(
        'status', status,
        'sent_at', sent_at,
        'accepted_at', accepted_at,
        'declined_at', declined_at
    ) AS metadata
FROM offers
WHERE application_id = @application_id

UNION ALL

-- Audit Logs (filtered to application)
SELECT
    'system_event' AS event_type,
    CONCAT('audit_', id) AS event_id,
    action AS title,
    '' AS description,
    created_at AS occurred_at,
    user_id AS actor_id,
    (SELECT display_name FROM users WHERE id = user_id) AS actor_name,
    metadata
FROM audit_logs
WHERE auditable_type = 'Application'
  AND auditable_id = @application_id

ORDER BY occurred_at DESC
LIMIT @per_page OFFSET @offset;
```

## UI/UX Requirements

### Screen/Component

- **Location:** Application detail view, "History" or "Activity" tab
- **Entry Point:** Tab navigation, timeline icon
- **Key Elements:**
  - Timeline visualization
  - Event type icons
  - Actor avatars
  - Timestamps (relative and absolute)
  - Expandable details
  - Filter controls
  - View toggle (timeline/list)

### Timeline View

```
+-----------------------------------------------------------------------------+
| Jane Doe - Software Engineer                                                |
| [Overview] [History] [Documents] [Notes] [Interviews] [Offers]              |
+-----------------------------------------------------------------------------+
| Application History                                                         |
| [All Events v] [Timeline | List]                              [Export]     |
+-----------------------------------------------------------------------------+
|                                                                             |
| TODAY                                                                       |
| +-------------------------------------------------------------------------+ |
| | [O] 2:30 PM   Moved to Offer Stage                                      | |
| |              by Sarah Chen                                              | |
| |              From: On-site Interview -> To: Offer                       | |
| +-------------------------------------------------------------------------+ |
|                                                                             |
| JANUARY 23, 2026                                                            |
| +-------------------------------------------------------------------------+ |
| | [*] 4:15 PM   Scorecard Submitted                                       | |
| |              by Mike Johnson                                            | |
| |              Recommendation: Strong Hire | Rating: 4.5/5                | |
| |              [View Scorecard]                                           | |
| +-------------------------------------------------------------------------+ |
| | [*] 3:45 PM   Scorecard Submitted                                       | |
| |              by Emily Wang                                              | |
| |              Recommendation: Hire | Rating: 4/5                         | |
| |              [View Scorecard]                                           | |
| +-------------------------------------------------------------------------+ |
| | [cal] 10:00 AM - 11:30 AM   On-site Interview Completed                 | |
| |                             Panel: Mike Johnson, Emily Wang, Tom Lee    | |
| |                             [View Interview Details]                    | |
| +-------------------------------------------------------------------------+ |
|                                                                             |
| JANUARY 20, 2026                                                            |
| +-------------------------------------------------------------------------+ |
| | [O] 11:00 AM   Moved to On-site Interview                               | |
| |               by Sarah Chen                                             | |
| |               Notes: Strong phone screen, advance to panel              | |
| +-------------------------------------------------------------------------+ |
|                                                                             |
| JANUARY 18, 2026                                                            |
| +-------------------------------------------------------------------------+ |
| | [cal] 3:00 PM   Phone Screen Completed                                  | |
| |                 Interviewer: Sarah Chen                                 | |
| |                 Duration: 45 minutes                                    | |
| +-------------------------------------------------------------------------+ |
|                                                                             |
| JANUARY 15, 2026                                                            |
| +-------------------------------------------------------------------------+ |
| | [O] 9:00 AM   Moved to Phone Screen                                     | |
| |              by Sarah Chen                                              | |
| +-------------------------------------------------------------------------+ |
| | [+] 8:30 AM   Application Received                                      | |
| |              Source: LinkedIn                                           | |
| |              Applied for: Software Engineer - San Francisco             | |
| +-------------------------------------------------------------------------+ |
|                                                                             |
| [Load Earlier Activity]                                                     |
+-----------------------------------------------------------------------------+

Legend:
[O]   - Stage change
[+]   - Application created
[*]   - Scorecard/feedback
[cal] - Interview
[mail]- Communication
[doc] - Document
[!]   - Important event (rejection, offer)
```

### Event Detail Expanded

```
+-------------------------------------------------------------------------+
| [O] 2:30 PM   Moved to Offer Stage                              [^]    |
|              by Sarah Chen                                              |
|                                                                         |
| +---------------------------------------------------------------------+ |
| | From Stage:    On-site Interview                                    | |
| | To Stage:      Offer                                                | |
| | Time in Stage: 3 days                                               | |
| |                                                                     | |
| | Notes:                                                              | |
| | All interviewers recommend hire. Strong technical skills and        | |
| | excellent culture fit. Moving to offer stage pending comp           | |
| | discussion with HR.                                                 | |
| |                                                                     | |
| | [View Full Transition]  [View Offer]                                | |
| +---------------------------------------------------------------------+ |
+-------------------------------------------------------------------------+
```

### Filter Options

```
+---------------------------+
| Event Type                |
+---------------------------+
| (*) All Events            |
| ( ) Stage Changes         |
| ( ) Interviews            |
| ( ) Scorecards            |
| ( ) Offers                |
| ( ) Communications        |
| ( ) Notes                 |
| ( ) Documents             |
| ( ) System Events         |
+---------------------------+
```

## Non-Functional Requirements

| Requirement | Target |
|-------------|--------|
| Initial Load | < 1 second for first 50 events |
| Scroll Performance | Smooth infinite scroll |
| Filter Response | < 300ms to apply filter |
| Total Events | Support up to 1000 events per app |
| Export | PDF/CSV export within 5 seconds |

## Security Considerations

- [x] Authentication required
- [x] Authorization per application
- [x] Internal notes hidden from candidates
- [x] PII masked in exported data (configurable)
- [x] Audit log entries read-only display
- [x] No modification capability from history view

## Related Use Cases

| Use Case | Relationship |
|----------|--------------|
| UC-102 View Pipeline | Context where history is accessed |
| UC-103 Move Stage | Creates stage transition events |
| UC-105 Reject Candidate | Creates rejection event |
| UC-107 Withdraw Application | Creates withdrawal event |
| UC-108 Reopen Application | Creates reopen event |
| UC-150 Schedule Interview | Creates interview events |
| UC-200 Submit Scorecard | Creates scorecard events |
| UC-307 View Audit Trail | Related compliance view |

---

## Data Model References

> Cross-references to [DATA_MODEL.md](../DATA_MODEL.md) and [CRUD_MATRIX.md](../CRUD_MATRIX.md)

### Subject Areas

| Subject Area | ID | Relationship |
|--------------|-----|--------------|
| Application Pipeline | SA-05 | Primary |
| Interview | SA-06 | Secondary |
| Evaluation | SA-07 | Secondary |
| Offer Management | SA-08 | Secondary |
| Compliance & Audit | SA-09 | Secondary |
| Communication | SA-10 | Secondary |

### Entities CRUD

| Entity | C | R | U | D | Notes |
|--------|---|---|---|---|-------|
| Application | | X | | | Base record for history |
| StageTransition | | X | | | All transitions for app |
| AuditLog | | X | | | Filtered by application |
| Interview | | X | | | All interviews for app |
| Scorecard | | X | | | All submitted scorecards |
| Offer | | X | | | All offers for app |
| CandidateNote | | X | | | Notes related to app |
| EmailLog | | X | | | Communications for app |

**Legend:** C = Create, R = Read, U = Update, D = Delete

---

## Process Model References

> Cross-references to [PROCESS_MODEL.md](../PROCESS_MODEL.md) and [PROCESS_CRUD_MATRIX.md](../PROCESS_CRUD_MATRIX.md)

| Attribute | Value | Link |
|-----------|-------|------|
| **Elementary Business Process** | EP-0407: View Application History | [PROCESS_MODEL.md#ep-0407](../PROCESS_MODEL.md#ep-0407-view-application-history) |
| **Business Process** | BP-104: Pipeline Management | [PROCESS_MODEL.md#bp-104](../PROCESS_MODEL.md#bp-104-pipeline-management) |
| **Business Function** | BF-01: Talent Acquisition | [PROCESS_MODEL.md#bf-01](../PROCESS_MODEL.md#bf-01-talent-acquisition) |

### EBP Details

| Attribute | Value |
|-----------|-------|
| **Trigger** | User clicks "History" tab on application or navigates to history URL |
| **Input** | Application ID, optional filters |
| **Output** | Chronological timeline of all application events |
| **Business Rules** | BR-109.1 through BR-109.7 (see Business Rules section) |

---

## Traceability Matrix

> Complete artifact mapping for requirements traceability

| Artifact Type | ID | Name | Link |
|---------------|-----|------|------|
| **Use Case** | UC-109 | View Application History | *(this document)* |
| **Elementary Process** | EP-0407 | View Application History | [PROCESS_MODEL.md](../PROCESS_MODEL.md#ep-0407-view-application-history) |
| **Business Process** | BP-104 | Pipeline Management | [PROCESS_MODEL.md](../PROCESS_MODEL.md#bp-104-pipeline-management) |
| **Business Function** | BF-01 | Talent Acquisition | [PROCESS_MODEL.md](../PROCESS_MODEL.md#bf-01-talent-acquisition) |
| **Primary Actor** | ACT-02 | Recruiter | [ACTORS.md](../ACTORS.md#act-02-recruiter) |
| **Subject Area (Primary)** | SA-05 | Application Pipeline | [DATA_MODEL.md](../DATA_MODEL.md#sa-05-application-pipeline) |
| **Subject Area (Secondary)** | SA-09 | Compliance & Audit | [DATA_MODEL.md](../DATA_MODEL.md#sa-09-compliance-audit) |
| **CRUD Matrix Row** | UC-109 | - | [CRUD_MATRIX.md](../CRUD_MATRIX.md#uc-109) |
| **Process CRUD Row** | EP-0407 | - | [PROCESS_CRUD_MATRIX.md](../PROCESS_CRUD_MATRIX.md#ep-0407) |

### Implementation Artifacts

| Artifact Type | Path/Reference | Status |
|---------------|----------------|--------|
| Controller | `app/controllers/admin/application_histories_controller.rb` | Planned |
| Query | `app/queries/application_history_query.rb` | Planned |
| View | `app/views/admin/applications/_history_tab.html.erb` | Planned |
| Stimulus | `app/javascript/controllers/timeline_controller.js` | Planned |
| Test | `test/queries/application_history_query_test.rb` | Planned |

---

## Open Questions

1. How long to retain detailed history (beyond audit requirements)?
2. Support for adding comments/annotations to historical events?
3. Integration with external calendar for interview timeline?
4. Export format options (PDF, CSV, JSON)?

## Change History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-01-25 | System | Initial draft |
