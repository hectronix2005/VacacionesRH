import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tab-switcher"
export default class extends Controller {
  static targets = ["content", "button"]
  static values = { defaultTab: String }

  connect() {
    // Initialize with default tab or first tab
    const defaultTab = this.defaultTabValue || this.buttonTargets[0]?.dataset.tab
    if (defaultTab) {
      this.showTab({ params: { tab: defaultTab } })
    }
  }

  showTab(event) {
    const tabName = event.params.tab
    
    // Hide all tab contents
    this.contentTargets.forEach(content => {
      content.classList.add('hidden')
    })
    
    // Show selected tab content
    const selectedContent = this.contentTargets.find(content => 
      content.id === `content-${tabName}`
    )
    if (selectedContent) {
      selectedContent.classList.remove('hidden')
    }
    
    // Update tab buttons
    this.buttonTargets.forEach(button => {
      button.classList.remove('border-blue-500', 'text-blue-600')
      button.classList.add('border-transparent', 'text-gray-500')
    })
    
    // Activate selected button
    const activeButton = this.buttonTargets.find(button => 
      button.dataset.tab === tabName
    )
    if (activeButton) {
      activeButton.classList.remove('border-transparent', 'text-gray-500')
      activeButton.classList.add('border-blue-500', 'text-blue-600')
    }
  }
}