import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "sidebar", "loader", "count"]

  connect() {
    this.currentPage = 1
    this.loading = false
    this.hasMore = document.getElementById('pagination-anchor').dataset.hasMore === 'true'
    this.initializeMap()
  }

  initializeMap() {
    // Initialize the map with a default location (will be updated by geolocation)
    this.map = L.map(this.containerTarget).setView([40.7128, -74.0060], 13)

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors',
      maxZoom: 19
    }).addTo(this.map)

    this.markers = []
    this.markerLayer = L.layerGroup().addTo(this.map)

    // Try to get user's current location
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const userLat = position.coords.latitude
          const userLng = position.coords.longitude

          // Set zoom level to approximately 500 feet view (zoom level 17-18)
          this.map.setView([userLat, userLng], 17)
        },
        (error) => {
          console.log('Geolocation error:', error)
          // If geolocation fails, load markers for default view
          this.loadMarkers()
        }
      )
    } else {
      // If geolocation not supported, load markers for default view
      this.loadMarkers()
    }

    // Add event listener for map movement
    this.map.on('moveend', () => {
      this.refreshIssuesForBounds()
    })
  }

  loadMarkers() {
    const issues = this.getIssuesData()

    issues.forEach(issue => {
      this.addMarker(issue)
    })
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

    // Include current map bounds in the request
    const bounds = this.map.getBounds()
    const boundsParams = JSON.stringify({
      north: bounds.getNorth(),
      south: bounds.getSouth(),
      east: bounds.getEast(),
      west: bounds.getWest()
    })

    try {
      // Build URL with current filter parameters from the page URL
      const currentUrl = new URL(window.location.href)
      const params = new URLSearchParams(currentUrl.search)
      params.set('page', nextPage)
      params.set('bounds', boundsParams)

      const response = await fetch(`/issues/public?${params.toString()}`, {
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

  async refreshIssuesForBounds() {
    if (this.loading) return

    const bounds = this.map.getBounds()
    const boundsParams = JSON.stringify({
      north: bounds.getNorth(),
      south: bounds.getSouth(),
      east: bounds.getEast(),
      west: bounds.getWest()
    })

    this.loading = true
    this.loaderTarget?.classList.remove('hidden')

    try {
      // Build URL with current filter parameters from the page URL
      const currentUrl = new URL(window.location.href)
      const params = new URLSearchParams(currentUrl.search)
      params.set('bounds', boundsParams)

      const response = await fetch(`/issues/public?${params.toString()}`, {
        headers: {
          'Accept': 'text/html'
        }
      })

      if (response.ok) {
        const html = await response.text()

        // Parse the response to extract the issues list
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const newIssuesList = doc.getElementById('issues-list')
        const newPaginationAnchor = doc.getElementById('pagination-anchor')

        if (newIssuesList) {
          // Replace the issues list
          document.getElementById('issues-list').innerHTML = newIssuesList.innerHTML

          // Update pagination anchor
          if (newPaginationAnchor) {
            document.getElementById('pagination-anchor').outerHTML = newPaginationAnchor.outerHTML
            this.hasMore = document.getElementById('pagination-anchor').dataset.hasMore === 'true'
          }

          // Clear existing markers and add new ones
          this.markerLayer.clearLayers()
          this.markers = []
          this.loadMarkers()
        }
      }
    } catch (error) {
      console.error('Error refreshing issues:', error)
    } finally {
      this.loading = false
      this.loaderTarget?.classList.add('hidden')
    }
  }
}
