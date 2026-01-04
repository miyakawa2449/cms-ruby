import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="media-upload"
export default class extends Controller {
  static targets = ["dropzone", "input", "previewArea", "previews", "progressArea", "progressBar", "progressText", "submitBtn"]

  connect() {
    this.files = []
  }

  // Drag and drop handlers
  dragover(event) {
    event.preventDefault()
    event.stopPropagation()
  }

  dragenter(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.add('border-blue-400', 'bg-blue-50')
  }

  dragleave(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.remove('border-blue-400', 'bg-blue-50')
  }

  drop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.remove('border-blue-400', 'bg-blue-50')

    const files = event.dataTransfer.files
    this.processFiles(files)
  }

  // File input change handler
  handleFiles(event) {
    const files = event.target.files
    this.processFiles(files)
  }

  // Process selected files
  processFiles(fileList) {
    const validFiles = Array.from(fileList).filter(file => {
      // Check if image
      if (!file.type.startsWith('image/')) {
        alert(`${file.name} は画像ファイルではありません`)
        return false
      }
      // Check size (10MB max)
      if (file.size > 10 * 1024 * 1024) {
        alert(`${file.name} のサイズが大きすぎます（最大10MB）`)
        return false
      }
      return true
    })

    if (validFiles.length === 0) return

    this.files = [...this.files, ...validFiles]
    this.showPreviews()
  }

  // Show file previews
  showPreviews() {
    if (!this.hasPreviewsTarget) return

    this.previewAreaTarget.classList.remove('hidden')
    this.previewsTarget.innerHTML = ''

    this.files.forEach((file, index) => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const previewHtml = `
          <div class="flex items-center gap-3 p-2 bg-gray-50 rounded-lg" data-index="${index}">
            <img src="${e.target.result}" class="w-12 h-12 object-cover rounded" alt="${file.name}">
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate">${file.name}</p>
              <p class="text-xs text-gray-500">${this.formatFileSize(file.size)}</p>
            </div>
            <button type="button"
                    class="p-1 text-gray-400 hover:text-red-600"
                    data-action="click->media-upload#removeFile"
                    data-index="${index}">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        `
        this.previewsTarget.insertAdjacentHTML('beforeend', previewHtml)
      }
      reader.readAsDataURL(file)
    })
  }

  // Remove file from list
  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.files.splice(index, 1)

    if (this.files.length === 0) {
      this.previewAreaTarget.classList.add('hidden')
    } else {
      this.showPreviews()
    }
  }

  // Upload handler
  async upload(event) {
    event.preventDefault()

    if (this.files.length === 0) {
      alert('アップロードするファイルを選択してください')
      return
    }

    const formData = new FormData()
    this.files.forEach(file => {
      formData.append('images[]', file)
    })

    // Get checkbox value
    const generateThumbnails = event.target.querySelector('[name="generate_thumbnails"]')?.checked || true
    formData.append('generate_thumbnails', generateThumbnails)

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    // Show progress
    this.showProgress()
    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.textContent = 'アップロード中...'

    try {
      const xhr = new XMLHttpRequest()

      // Progress tracking
      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable) {
          const percent = Math.round((e.loaded / e.total) * 100)
          this.updateProgress(percent)
        }
      })

      xhr.onload = () => {
        if (xhr.status === 200 || xhr.status === 201) {
          const data = JSON.parse(xhr.responseText)
          if (data.success) {
            window.location.reload()
          } else {
            this.showError(data.error || 'アップロードに失敗しました')
          }
        } else {
          this.showError('アップロードに失敗しました')
        }
        this.resetForm()
      }

      xhr.onerror = () => {
        this.showError('ネットワークエラーが発生しました')
        this.resetForm()
      }

      xhr.open('POST', event.target.action)
      xhr.setRequestHeader('X-CSRF-Token', csrfToken)
      xhr.setRequestHeader('Accept', 'application/json')
      xhr.send(formData)

    } catch (error) {
      console.error('Upload error:', error)
      this.showError(`エラー: ${error.message}`)
      this.resetForm()
    }
  }

  // Show progress area
  showProgress() {
    if (this.hasProgressAreaTarget) {
      this.progressAreaTarget.classList.remove('hidden')
    }
  }

  // Update progress bar
  updateProgress(percent) {
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percent}%`
    }
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `${percent}%`
    }
  }

  // Reset form
  resetForm() {
    this.files = []
    if (this.hasInputTarget) {
      this.inputTarget.value = ''
    }
    if (this.hasPreviewAreaTarget) {
      this.previewAreaTarget.classList.add('hidden')
    }
    if (this.hasPreviewsTarget) {
      this.previewsTarget.innerHTML = ''
    }
    if (this.hasProgressAreaTarget) {
      this.progressAreaTarget.classList.add('hidden')
    }
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = '0%'
    }
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.textContent = 'アップロード'
    }
  }

  // Show error message
  showError(message) {
    alert(message)
  }

  // Format file size
  formatFileSize(bytes) {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }
}
