import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="map"
export default class extends Controller {
  static targets = ["container", "latitude", "longitude", "address"]
  static values = {
    latitude: Number,
    longitude: Number,
    address: String,
    editable: { type: Boolean, default: true }
  }

  connect() {
    console.log("Map controller connected!")
    console.log("Container target:", this.containerTarget)

    // Wait for Leaflet to be available
    if (typeof L === 'undefined') {
      console.error('Leaflet is not loaded - waiting...')
      // Try again after a short delay
      setTimeout(() => this.initializeMap(), 100)
      return
    }
    this.initializeMap()
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }

  initializeMap() {
    console.log("Initializing map...")

    // Check again if Leaflet is available
    if (typeof L === 'undefined') {
      console.error('Leaflet still not available')
      return
    }

    // Default center (San Francisco if no location set)
    const defaultLat = this.latitudeValue || 37.7749
    const defaultLng = this.longitudeValue || -122.4194
    const defaultZoom = this.latitudeValue ? 15 : 13

    console.log("Creating map at:", defaultLat, defaultLng)

    // Initialize the map
    this.map = L.map(this.containerTarget).setView([defaultLat, defaultLng], defaultZoom)

    // Add OpenStreetMap tiles
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors',
      maxZoom: 19
    }).addTo(this.map)

    // Create custom icon using URL-encoded SVG
    const svgIcon = encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#dc2626" width="32" height="40"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>')

    const icon = L.icon({
      iconUrl: 'data:image/svg+xml,' + svgIcon,
      iconSize: [32, 40],
      iconAnchor: [16, 40],
      popupAnchor: [0, -40]
    })

    if (this.editableValue) {
      console.log("Creating editable map...")
      // Editable mode for forms
      this.marker = L.marker([defaultLat, defaultLng], {
        draggable: true,
        icon: icon
      }).addTo(this.map)

      // Add address popup if available
      if (this.addressValue) {
        this.marker.bindPopup(this.addressValue).openPopup()
      }

      // Handle marker drag
      this.marker.on('dragend', () => {
        const position = this.marker.getLatLng()
        this.updateLocation(position.lat, position.lng)
      })

      // Handle map click to move marker
      this.map.on('click', (e) => {
        this.marker.setLatLng(e.latlng)
        this.updateLocation(e.latlng.lat, e.latlng.lng)
      })

      // Try to get user's current location
      if (!this.latitudeValue && navigator.geolocation) {
        console.log("Getting user location...")
        navigator.geolocation.getCurrentPosition(
          (position) => {
            const { latitude, longitude } = position.coords
            console.log("Got user location:", latitude, longitude)
            this.map.setView([latitude, longitude], 15)
            this.marker.setLatLng([latitude, longitude])
            this.updateLocation(latitude, longitude)
          },
          (error) => {
            console.log("Geolocation error:", error)
          }
        )
      }
    } else {
      // View-only mode
      const marker = L.marker([defaultLat, defaultLng], { icon: icon }).addTo(this.map)

      if (this.addressValue) {
        marker.bindPopup(this.addressValue).openPopup()
      }
    }
  }

  async updateLocation(lat, lng) {
    console.log("Updating location to:", lat, lng)

    // Update hidden form fields
    if (this.hasLatitudeTarget) {
      this.latitudeTarget.value = lat
    }
    if (this.hasLongitudeTarget) {
      this.longitudeTarget.value = lng
    }

    // Perform reverse geocoding to get address
    try {
      const response = await fetch(`https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&addressdetails=1`)
      const data = await response.json()

      if (data && data.display_name) {
        // Extract a more concise address
        const address = this.formatAddress(data)
        console.log("Got address:", address)

        if (this.hasAddressTarget) {
          this.addressTarget.value = address
        }

        // Update popup
        this.marker.bindPopup(address).openPopup()
      }
    } catch (error) {
      console.error("Geocoding error:", error)
    }
  }

  formatAddress(data) {
    const parts = []
    const addr = data.address

    // Build a concise address from available parts
    if (addr.house_number) parts.push(addr.house_number)
    if (addr.road) parts.push(addr.road)
    else if (addr.pedestrian) parts.push(addr.pedestrian)
    else if (addr.footway) parts.push(addr.footway)

    // Add neighborhood or suburb
    if (addr.neighbourhood) parts.push(addr.neighbourhood)
    else if (addr.suburb) parts.push(addr.suburb)

    // Add city
    if (addr.city) parts.push(addr.city)
    else if (addr.town) parts.push(addr.town)
    else if (addr.village) parts.push(addr.village)

    // If we have a good address, return it, otherwise use the full display name
    return parts.length > 0 ? parts.join(', ') : data.display_name
  }
}