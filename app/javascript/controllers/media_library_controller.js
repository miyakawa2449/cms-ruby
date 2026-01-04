import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="media-library"
export default class extends Controller {
  static targets = ["uploadModal", "detailModal", "detailContent", "bulkDeleteBtn"]
  static values = {
    view: String,
    detailUrl: { type: String, default: "/admin/media" }
  }

  connect() {
    this.selectedIds = new Set()
  }

  // View mode switching
  switchView(event) {
    const view = event.currentTarget.dataset.view
    const currentUrl = new URL(window.location.href)
    currentUrl.searchParams.set('view', view)
    window.location.href = currentUrl.toString()
  }

  // Upload modal
  openUploadModal() {
    if (this.hasUploadModalTarget) {
      this.uploadModalTarget.classList.remove('hidden')
      document.body.classList.add('overflow-hidden')
    }
  }

  closeUploadModal() {
    if (this.hasUploadModalTarget) {
      this.uploadModalTarget.classList.add('hidden')
      document.body.classList.remove('overflow-hidden')
    }
  }

  // Detail modal
  async showDetail(event) {
    const id = event.currentTarget.dataset.id
    if (!id) return

    try {
      const response = await fetch(`${this.detailUrlValue}/${id}`, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        // Navigate to detail page
        window.location.href = `${this.detailUrlValue}/${id}`
      }
    } catch (error) {
      console.error('Error loading detail:', error)
    }
  }

  closeDetailModal() {
    if (this.hasDetailModalTarget) {
      this.detailModalTarget.classList.add('hidden')
      document.body.classList.remove('overflow-hidden')
    }
  }

  // Selection management
  toggleSelection(event) {
    const checkbox = event.currentTarget
    const id = checkbox.dataset.id

    if (checkbox.checked) {
      this.selectedIds.add(id)
    } else {
      this.selectedIds.delete(id)
    }

    this.updateBulkDeleteButton()
  }

  updateBulkDeleteButton() {
    if (this.hasBulkDeleteBtnTarget) {
      if (this.selectedIds.size > 0) {
        this.bulkDeleteBtnTarget.classList.remove('hidden')
        this.bulkDeleteBtnTarget.textContent = `${this.selectedIds.size}件を削除`
      } else {
        this.bulkDeleteBtnTarget.classList.add('hidden')
      }
    }
  }

  // Bulk delete
  async bulkDelete() {
    if (this.selectedIds.size === 0) return

    const confirmed = confirm(`選択した${this.selectedIds.size}件の画像を削除しますか？`)
    if (!confirmed) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    try {
      const response = await fetch(`${this.detailUrlValue}/bulk_destroy`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ ids: Array.from(this.selectedIds) })
      })

      if (response.ok) {
        window.location.reload()
      } else {
        const data = await response.json()
        alert(data.error || '削除に失敗しました')
      }
    } catch (error) {
      console.error('Bulk delete error:', error)
      alert('削除中にエラーが発生しました')
    }
  }

  // Close modals on escape key
  closeOnEscape(event) {
    if (event.key === 'Escape') {
      this.closeUploadModal()
      this.closeDetailModal()
    }
  }
}
