import { Controller } from "@hotwired/stimulus"

// Controller for date range picker in reports
export default class extends Controller {
  static targets = ["select", "customFields", "startDate", "endDate"]

  connect() {
    this.toggleCustomFields()
  }

  // Toggle visibility of custom date fields based on selection
  toggle() {
    this.toggleCustomFields()
  }

  toggleCustomFields() {
    if (!this.hasSelectTarget || !this.hasCustomFieldsTarget) return

    const isCustom = this.selectTarget.value === "custom"
    this.customFieldsTarget.classList.toggle("d-none", !isCustom)

    // Set required attribute on custom fields
    if (this.hasStartDateTarget && this.hasEndDateTarget) {
      this.startDateTarget.required = isCustom
      this.endDateTarget.required = isCustom
    }
  }

  // Validate date range
  validate(event) {
    if (!this.hasStartDateTarget || !this.hasEndDateTarget) return

    const startDate = new Date(this.startDateTarget.value)
    const endDate = new Date(this.endDateTarget.value)

    if (startDate > endDate) {
      event.preventDefault()
      alert("Start date must be before end date")
      return false
    }

    // Check for reasonable range (max 1 year)
    const daysDiff = (endDate - startDate) / (1000 * 60 * 60 * 24)
    if (daysDiff > 365) {
      event.preventDefault()
      alert("Date range cannot exceed 1 year")
      return false
    }

    return true
  }

  // Submit form when preset changes
  submitOnChange(event) {
    if (event.target.value !== "custom") {
      event.target.form.submit()
    }
  }
}
