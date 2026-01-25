import { Controller } from "@hotwired/stimulus"

// Pipeline controller for Kanban drag-drop functionality
export default class extends Controller {
  static targets = ["column"]

  connect() {
    this.draggedCard = null
  }

  // Called when drag starts on a card
  dragStart(event) {
    this.draggedCard = event.target.closest('.pipeline-card')
    if (!this.draggedCard) return

    // Set drag data
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/plain', this.draggedCard.dataset.applicationId)

    // Add visual feedback
    setTimeout(() => {
      this.draggedCard.classList.add('opacity-50', 'border-primary')
    }, 0)
  }

  // Called when drag ends
  dragEnd(event) {
    if (this.draggedCard) {
      this.draggedCard.classList.remove('opacity-50', 'border-primary')
      this.draggedCard = null
    }

    // Remove drop zone indicators
    this.columnTargets.forEach(column => {
      column.classList.remove('bg-light', 'border-primary')
    })
  }

  // Called when dragging over a drop zone
  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'

    const column = event.target.closest('[data-pipeline-target="column"]')
    if (column) {
      column.classList.add('bg-light')
    }
  }

  // Called when item is dropped
  drop(event) {
    event.preventDefault()

    const column = event.target.closest('[data-pipeline-target="column"]')
    if (!column || !this.draggedCard) return

    const applicationId = event.dataTransfer.getData('text/plain')
    const stageId = column.dataset.stageId

    // Get current stage from card's parent column
    const currentStageId = this.draggedCard.closest('[data-pipeline-target="column"]')?.dataset.stageId

    // Don't process if dropped in same column
    if (currentStageId === stageId) {
      column.classList.remove('bg-light')
      return
    }

    // Move card visually (optimistic update)
    const emptyPlaceholder = column.querySelector('.text-center.text-muted')
    if (emptyPlaceholder) {
      emptyPlaceholder.remove()
    }
    column.appendChild(this.draggedCard)

    // Remove empty state from source if needed
    this.updateEmptyStates()

    // Submit move to server
    this.moveStage(applicationId, stageId)

    column.classList.remove('bg-light')
  }

  // Send move request to server
  async moveStage(applicationId, stageId) {
    const jobId = this.extractJobId()
    if (!jobId) {
      console.error('Could not determine job ID')
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const url = `/jobs/${jobId}/pipeline/applications/${applicationId}/move_stage`

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRF-Token': csrfToken,
          'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml'
        },
        body: `stage_id=${stageId}`
      })

      if (!response.ok) {
        // Revert on error - reload page to get correct state
        console.error('Move failed:', response.statusText)
        window.location.reload()
      }
    } catch (error) {
      console.error('Move request failed:', error)
      window.location.reload()
    }
  }

  // Extract job ID from URL
  extractJobId() {
    const match = window.location.pathname.match(/\/jobs\/(\d+)/)
    return match ? match[1] : null
  }

  // Update empty state placeholders in columns
  updateEmptyStates() {
    this.columnTargets.forEach(column => {
      const cards = column.querySelectorAll('.pipeline-card')
      const existingPlaceholder = column.querySelector('.text-center.text-muted')

      if (cards.length === 0 && !existingPlaceholder) {
        const placeholder = document.createElement('div')
        placeholder.className = 'text-center text-muted py-4'
        placeholder.innerHTML = '<i class="bi bi-inbox fs-3 d-block mb-2"></i><small>No candidates</small>'
        column.appendChild(placeholder)
      }
    })
  }

  // Update column counts after move
  updateColumnCounts() {
    const columns = this.element.querySelectorAll('.pipeline-column')
    columns.forEach(col => {
      const stageId = col.dataset.stageId
      const column = col.querySelector('[data-pipeline-target="column"]')
      const count = column ? column.querySelectorAll('.pipeline-card').length : 0
      const badge = col.querySelector('.badge')
      if (badge) {
        badge.textContent = count
      }
    })
  }
}
