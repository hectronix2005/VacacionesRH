import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["modal", "form"]
  static values = { 
    actionUrl: String,
    closeOnOutsideClick: { type: Boolean, default: true }
  }

  connect() {
    // Add event listener for outside clicks if enabled
    if (this.closeOnOutsideClickValue) {
      this.modalTarget.addEventListener('click', this.handleOutsideClick.bind(this))
    }
  }

  disconnect() {
    // Clean up event listener
    if (this.closeOnOutsideClickValue) {
      this.modalTarget.removeEventListener('click', this.handleOutsideClick.bind(this))
    }
  }

  show(event) {
    // Get request ID from the event or data attribute
    const requestId = event.params?.requestId || event.currentTarget.dataset.requestId
    
    if (requestId && this.hasFormTarget) {
      // Update form action with request ID
      const baseUrl = this.actionUrlValue || '/vacation_requests'
      this.formTarget.action = `${baseUrl}/${requestId}/reject`
    }
    
    // Show the modal
    this.modalTarget.classList.remove('hidden')
  }

  hide() {
    // Hide the modal and reset form
    this.modalTarget.classList.add('hidden')
    
    if (this.hasFormTarget) {
      this.formTarget.reset()
    }
  }

  handleOutsideClick(event) {
    // Close modal if clicking on the backdrop (not the modal content)
    if (event.target === this.modalTarget) {
      this.hide()
    }
  }

  // Action to handle ESC key press
  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.hide()
    }
  }
}