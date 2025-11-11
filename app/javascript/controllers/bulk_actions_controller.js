import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="bulk-actions"
export default class extends Controller {
  static values = {
    confirmMessage: { type: String, default: "¿Estás seguro de que quieres realizar esta acción?" },
    pendingImplementationMessage: { type: String, default: "Funcionalidad pendiente de implementación" }
  }

  bulkApprove() {
    const confirmMessage = this.confirmMessageValue || 
      "¿Estás seguro de que quieres aprobar todas las solicitudes que puedes aprobar?"
    
    if (confirm(confirmMessage)) {
      // This would require additional backend implementation
      // For now, show a pending implementation message
      alert(this.pendingImplementationMessageValue)
      
      // In a real implementation, you would:
      // 1. Collect all approvable request IDs
      // 2. Send a batch request to the server
      // 3. Handle the response and update the UI
      // this.performBulkApproval()
    }
  }

  // Future implementation for actual bulk approval
  async performBulkApproval() {
    try {
      // Collect all requests that can be approved
      const approvableRequests = this.getApprovableRequests()
      
      if (approvableRequests.length === 0) {
        alert("No hay solicitudes que puedas aprobar")
        return
      }

      // Send batch approval request
      const response = await fetch('/vacation_requests/bulk_approve', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          request_ids: approvableRequests,
          comments: "Aprobación masiva"
        })
      })

      if (response.ok) {
        // Reload page or update UI
        window.location.reload()
      } else {
        alert("Error al procesar las aprobaciones masivas")
      }
    } catch (error) {
      console.error('Error in bulk approval:', error)
      alert("Error al procesar las aprobaciones masivas")
    }
  }

  getApprovableRequests() {
    // This would collect request IDs from the current view
    // Implementation depends on how the data is structured in the DOM
    const approvableButtons = this.element.querySelectorAll('[data-approvable="true"]')
    return Array.from(approvableButtons).map(button => button.dataset.requestId)
  }

  // Generic bulk action handler for future extensibility
  performBulkAction(event) {
    const action = event.params.action
    const confirmMessage = event.params.confirmMessage || this.confirmMessageValue
    
    if (confirm(confirmMessage)) {
      // Dispatch custom event for handling different bulk actions
      this.dispatch('bulkAction', { 
        detail: { 
          action: action,
          controller: this 
        } 
      })
    }
  }
}