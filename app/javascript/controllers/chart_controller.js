import { Controller } from "@hotwired/stimulus"

// Chart controller for rendering Chart.js charts
// Uses data attributes to configure charts
export default class extends Controller {
  static values = {
    type: { type: String, default: "bar" },
    data: Object,
    options: { type: Object, default: {} }
  }

  static targets = ["canvas"]

  connect() {
    this.loadChartJs().then(() => {
      this.initializeChart()
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  async loadChartJs() {
    if (window.Chart) return

    // Load Chart.js from CDN if not already loaded
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js'
      script.async = true
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  initializeChart() {
    if (!this.hasCanvasTarget) {
      console.error('Chart controller requires a canvas target')
      return
    }

    const ctx = this.canvasTarget.getContext('2d')
    const config = this.buildConfig()

    this.chart = new window.Chart(ctx, config)
  }

  buildConfig() {
    const defaultOptions = this.getDefaultOptions()
    const mergedOptions = { ...defaultOptions, ...this.optionsValue }

    return {
      type: this.typeValue,
      data: this.dataValue,
      options: mergedOptions
    }
  }

  getDefaultOptions() {
    const baseOptions = {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: {
          position: 'bottom'
        }
      }
    }

    switch (this.typeValue) {
      case 'bar':
        return {
          ...baseOptions,
          scales: {
            y: {
              beginAtZero: true
            }
          }
        }
      case 'line':
        return {
          ...baseOptions,
          scales: {
            y: {
              beginAtZero: true
            }
          },
          elements: {
            line: {
              tension: 0.3
            }
          }
        }
      case 'pie':
      case 'doughnut':
        return {
          ...baseOptions,
          plugins: {
            legend: {
              position: 'right'
            }
          }
        }
      case 'funnel':
        return baseOptions
      default:
        return baseOptions
    }
  }

  // Update chart data dynamically
  updateData(newData) {
    if (!this.chart) return

    this.chart.data = newData
    this.chart.update()
  }

  // Refresh chart from URL
  async refresh() {
    const url = this.element.dataset.chartRefreshUrl
    if (!url) return

    try {
      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.updateData(data)
      }
    } catch (error) {
      console.error('Failed to refresh chart:', error)
    }
  }

  // Handle data attribute changes
  dataValueChanged() {
    if (this.chart && this.dataValue) {
      this.chart.data = this.dataValue
      this.chart.update()
    }
  }
}
