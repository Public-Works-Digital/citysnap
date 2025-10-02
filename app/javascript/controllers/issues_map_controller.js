import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "sidebar", "loader", "count"]

  connect() {
    this.initializeMap()
    this.loadMarkers()
    this.currentPage = 1
    this.loading = false
    this.hasMore = document.getElementById('pagination-anchor').dataset.hasMore === 'true'
  }

  initializeMap() {
    // Initialize the map centered on the first issue or a default location
    const firstIssue = this.getIssuesData()[0]
    const centerLat = firstIssue?.latitude || 40.7128
    const centerLng = firstIssue?.longitude || -74.0060

    this.map = L.map(this.containerTarget).setView([centerLat, centerLng], 12)

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors',
      maxZoom: 19
    }).addTo(this.map)

    this.markers = []
    this.markerLayer = L.layerGroup().addTo(this.map)
  }

  loadMarkers() {
    const issues = this.getIssuesData()

    issues.forEach(issue => {
      this.addMarker(issue)
    })

    // Fit map bounds to show all markers
    if (this.markers.length > 0) {
      const group = L.featureGroup(this.markers)
      this.map.fitBounds(group.getBounds().pad(0.1))
    }
  }

  addMarker(issue) {
    const marker = L.marker([issue.latitude, issue.longitude])
      .bindPopup(this.createPopupContent(issue))
      .addTo(this.markerLayer)

    marker.issueId = issue.id
    this.markers.push(marker)

    // Click handler to scroll to issue in sidebar
    marker.on('click', () => {
      this.scrollToIssue(issue.id)
    })
  }

  createPopupContent(issue) {
    return `
      <div class="text-sm">
        <div class="font-semibold mb-1">#${String(issue.id).padStart(6, '0')}</div>
        <p class="text-gray-700 mb-2">${issue.comment || 'No description'}</p>
        <a href="/issues/${issue.id}" class="text-red-600 hover:text-red-700 font-medium">View Details →</a>
      </div>
    `
  }

  getIssuesData() {
    const issueCards = this.sidebarTarget.querySelectorAll('[data-issue-id]')
    return Array.from(issueCards).map(card => ({
      id: parseInt(card.dataset.issueId),
      latitude: parseFloat(card.dataset.latitude),
      longitude: parseFloat(card.dataset.longitude),
      comment: card.querySelector('p').textContent.trim()
    }))
  }

  highlightIssue(event) {
    const card = event.currentTarget
    const issueId = parseInt(card.dataset.issueId)
    const latitude = parseFloat(card.dataset.latitude)
    const longitude = parseFloat(card.dataset.longitude)

    // Pan to marker
    this.map.setView([latitude, longitude], 16)

    // Open popup for this marker
    const marker = this.markers.find(m => m.issueId === issueId)
    if (marker) {
      marker.openPopup()
    }

    // Highlight the card briefly
    card.classList.add('bg-red-50')
    setTimeout(() => {
      card.classList.remove('bg-red-50')
    }, 1000)
  }

  scrollToIssue(issueId) {
    const card = this.sidebarTarget.querySelector(`[data-issue-id="${issueId}"]`)
    if (card) {
      card.scrollIntoView({ behavior: 'smooth', block: 'center' })
      card.classList.add('bg-red-50')
      setTimeout(() => {
        card.classList.remove('bg-red-50')
      }, 1000)
    }
  }

  handleScroll() {
    if (this.loading || !this.hasMore) return

    const sidebar = this.sidebarTarget
    const scrollPosition = sidebar.scrollTop + sidebar.clientHeight
    const scrollThreshold = sidebar.scrollHeight - 100

    if (scrollPosition >= scrollThreshold) {
      this.loadMoreIssues()
    }
  }

  async loadMoreIssues() {
    if (this.loading || !this.hasMore) return

    this.loading = true
    this.loaderTarget.classList.remove('hidden')

    const nextPage = document.getElementById('pagination-anchor').dataset.nextPage

    try {
      const response = await fetch(`/issues/public?page=${nextPage}`, {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })

      if (response.ok) {
        const html = await response.text()

        // Create a temporary container to parse the response
        const temp = document.createElement('div')
        temp.innerHTML = html

        // Extract and execute turbo-stream actions
        const turboStreams = temp.querySelectorAll('turbo-stream')
        turboStreams.forEach(stream => {
          const action = stream.getAttribute('action')
          const target = stream.getAttribute('target')
          const template = stream.querySelector('template')

          if (action === 'append' && target === 'issues-list' && template) {
            document.getElementById('issues-list').insertAdjacentHTML('beforeend', template.innerHTML)
          } else if (action === 'replace' && target === 'pagination-anchor' && template) {
            document.getElementById('pagination-anchor').outerHTML = template.innerHTML
          }
        })

        // Update pagination state
        const newAnchor = document.getElementById('pagination-anchor')
        this.hasMore = newAnchor.dataset.hasMore === 'true'
        this.currentPage = parseInt(nextPage)

        // Add markers for new issues
        this.updateMapMarkers()
      }
    } catch (error) {
      console.error('Error loading more issues:', error)
    } finally {
      this.loading = false
      this.loaderTarget.classList.add('hidden')
    }
  }

  updateMapMarkers() {
    // Get all issues currently in the sidebar
    const currentIssues = this.getIssuesData()
    const existingIds = this.markers.map(m => m.issueId)

    // Add markers for new issues
    currentIssues.forEach(issue => {
      if (!existingIds.includes(issue.id)) {
        this.addMarker(issue)
      }
    })

    // Update total count
    if (this.hasCountTarget) {
      this.countTarget.textContent = currentIssues.length
    }
  }
}
