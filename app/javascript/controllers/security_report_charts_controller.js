import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    chartData: Object
  }

  connect() {
    this.renderAttempts = 0
    this.renderCharts()
  }

  renderCharts() {
    if (!window.Chart) {
      if (this.renderAttempts < 10) {
        this.renderAttempts += 1
        setTimeout(() => this.renderCharts(), 50)
      }
      return
    }

    const scansCanvas = this.element.querySelector("#securityScansChart")
    const severityCanvas = this.element.querySelector("#vulnerabilitySeverityChart")
    if (!scansCanvas || !severityCanvas || scansCanvas.dataset.chartReady === "true") {
      return
    }

    scansCanvas.dataset.chartReady = "true"
    const chartData = this.chartDataValue || {}

    new window.Chart(scansCanvas, {
      type: "doughnut",
      data: {
        labels: (chartData.scans && chartData.scans.labels) || [],
        datasets: [{
          data: (chartData.scans && chartData.scans.data) || [],
          backgroundColor: [
            "rgba(99, 102, 241, 0.7)",
            "rgba(14, 165, 233, 0.7)",
            "rgba(34, 197, 94, 0.7)",
            "rgba(239, 68, 68, 0.7)"
          ],
          borderColor: [
            "rgb(99, 102, 241)",
            "rgb(14, 165, 233)",
            "rgb(34, 197, 94)",
            "rgb(239, 68, 68)"
          ],
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: "bottom" }
        }
      }
    })

    new window.Chart(severityCanvas, {
      type: "bar",
      data: {
        labels: (chartData.vulnerabilities && chartData.vulnerabilities.labels) || [],
        datasets: [{
          label: "件数",
          data: (chartData.vulnerabilities && chartData.vulnerabilities.data) || [],
          backgroundColor: [
            "rgba(220, 38, 38, 0.7)",
            "rgba(249, 115, 22, 0.7)",
            "rgba(234, 179, 8, 0.7)",
            "rgba(59, 130, 246, 0.7)",
            "rgba(107, 114, 128, 0.7)"
          ],
          borderColor: [
            "rgb(220, 38, 38)",
            "rgb(249, 115, 22)",
            "rgb(234, 179, 8)",
            "rgb(59, 130, 246)",
            "rgb(107, 114, 128)"
          ],
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: { stepSize: 1 }
          }
        },
        plugins: {
          legend: { display: false }
        }
      }
    })
  }
}
