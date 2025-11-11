import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = {
    url: String,
    placeholder: String,
    maxItems: Number,
    create: Boolean,
    searchField: String,
    valueField: String,
    labelField: String
  }

  connect() {
    this.initializeTomSelect()
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }

  initializeTomSelect() {
    const options = {
      placeholder: this.placeholderValue || "Seleccionar...",
      allowEmptyOption: true,
      searchField: this.searchFieldValue || ['text'],
      valueField: this.valueFieldValue || 'value',
      labelField: this.labelFieldValue || 'text',
      preload: true,
      plugins: ['remove_button', 'clear_button', 'dropdown_input'],
    }

    // Si hay una URL definida, configurar carga remota
    if (this.urlValue) {
      options.load = (query, callback) => {

        fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`)
          .then(response => response.json())
          .then(json => {
            callback(json)
            console.log("thene")
            console.log(json)
            console.log(json[0])
          })
          .catch(() => {
            callback()
          })
      }
    }

    // Configurar múltiples elementos si está definido
    if (this.maxItemsValue) {
      options.maxItems = this.maxItemsValue
    }

    this.tomSelect = new TomSelect(this.element, options)
  }
}
