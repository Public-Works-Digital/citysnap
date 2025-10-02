import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "dropzone"]

  connect() {
    this.updatePreview()
    this.setupDragAndDrop()
  }

  setupDragAndDrop() {
    const dropzone = this.hasDropzoneTarget ? this.dropzoneTarget : this.element

    // Prevent default drag behaviors
    ;['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      dropzone.addEventListener(eventName, this.preventDefaults.bind(this), false)
      document.body.addEventListener(eventName, this.preventDefaults.bind(this), false)
    })

    // Highlight drop area when item is dragged over it
    ;['dragenter', 'dragover'].forEach(eventName => {
      dropzone.addEventListener(eventName, () => this.highlight(dropzone), false)
    })

    ;['dragleave', 'drop'].forEach(eventName => {
      dropzone.addEventListener(eventName, () => this.unhighlight(dropzone), false)
    })

    // Handle dropped files
    dropzone.addEventListener('drop', this.handleDrop.bind(this), false)
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  highlight(dropzone) {
    dropzone.classList.add('border-red-500', 'bg-red-50')
  }

  unhighlight(dropzone) {
    dropzone.classList.remove('border-red-500', 'bg-red-50')
  }

  handleDrop(e) {
    const dt = e.dataTransfer
    const files = dt.files

    if (files.length > 0) {
      this.inputTarget.files = files
      this.updatePreview()
    }
  }

  updatePreview() {
    const file = this.inputTarget.files[0]

    if (file) {
      // Show file name and preview
      this.showFilePreview(file)
    } else {
      this.previewTarget.classList.add('hidden')
    }
  }

  showFilePreview(file) {
    const reader = new FileReader()

    reader.onload = (e) => {
      this.previewTarget.innerHTML = `
        <div class="flex items-center space-x-3 p-3 bg-green-50 border border-green-200 rounded-lg">
          <svg class="h-5 w-5 text-green-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-green-800 truncate">${file.name}</p>
            <p class="text-xs text-green-600">${this.formatFileSize(file.size)}</p>
          </div>
          ${file.type.startsWith('image/') ? `
            <img src="${e.target.result}" class="h-16 w-16 object-cover rounded border border-green-300" alt="Preview">
          ` : ''}
          <button type="button" data-action="click->file-upload#removeFile" class="flex-shrink-0 p-1 hover:bg-red-100 rounded-full transition-colors">
            <svg class="h-5 w-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      `
      this.previewTarget.classList.remove('hidden')
    }

    reader.readAsDataURL(file)
  }

  removeFile(event) {
    event.preventDefault()
    this.inputTarget.value = ''
    this.previewTarget.classList.add('hidden')
  }

  formatFileSize(bytes) {
    if (bytes < 1024) return bytes + ' B'
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
  }
}
