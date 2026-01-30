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

    const requestsCanvas = this.element.querySelector("#dailyRequestsChart")
    const costCanvas = this.element.querySelector("#dailyCostChart")
    if (!requestsCanvas || !costCanvas || requestsCanvas.dataset.chartReady === "true") {
      return
    }

    requestsCanvas.dataset.chartReady = "true"
    const chartData = this.chartDataValue || {}

    new window.Chart(requestsCanvas, {
      type: "bar",
      data: {
        labels: chartData.labels || [],
        datasets: [{
          label: "リクエスト数",
          data: (chartData.datasets && chartData.datasets.requests) || [],
          backgroundColor: "rgba(79, 70, 229, 0.5)",
          borderColor: "rgb(79, 70, 229)",
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

    new window.Chart(costCanvas, {
      type: "line",
      data: {
        labels: chartData.labels || [],
        datasets: [{
          label: "コスト (USD)",
          data: (chartData.datasets && chartData.datasets.cost) || [],
          backgroundColor: "rgba(16, 185, 129, 0.1)",
          borderColor: "rgb(16, 185, 129)",
          borderWidth: 2,
          fill: true,
          tension: 0.3
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: function(value) {
                return "$" + value.toFixed(4)
              }
            }
          }
        },
        plugins: {
          legend: { display: false }
        }
      }
    })
  }
}
