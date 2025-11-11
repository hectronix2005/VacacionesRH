import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="date-calculator"
export default class extends Controller {
  static targets = ["startDate", "endDate", "calculation", "text"]

  connect() {
    this.loadCountryWorkingDays()
    this.calculateDays()
  }

  async loadCountryWorkingDays() {
    try {
      const response = await fetch('/vacation_requests/country_working_days.json')
      if (response.ok) {
        this.countryData = await response.json()
        // Convertir el array de festivos a un Set para búsqueda rápida
        this.holidays = new Set(this.countryData.holidays || [])
      } else {
        console.error('Failed to load country working days configuration')
        // Fallback to default working days (Monday-Friday)
        this.countryData = {
          working_days: {
            monday: true,
            tuesday: true,
            wednesday: true,
            thursday: true,
            friday: true,
            saturday: false,
            sunday: false
          }
        }
        this.holidays = new Set()
      }
    } catch (error) {
      console.error('Error fetching country working days:', error)
      // Fallback to default working days
      this.countryData = {
        working_days: {
          monday: true,
          tuesday: true,
          wednesday: true,
          thursday: true,
          friday: true,
          saturday: false,
          sunday: false
        }
      }
      this.holidays = new Set()
    }
  }

  calculateDays() {
    const startDateValue = this.startDateTarget.value
    const endDateValue = this.endDateTarget.value
    
    if (startDateValue && endDateValue) {
      const startDate = this.parseLocalDate(startDateValue)
      const endDate = this.parseLocalDate(endDateValue)

      if (endDate >= startDate) {
        // Calculate business days using country configuration and holidays
        const businessDays = this.calculateBusinessDays(startDate, endDate)
        
        this.textTarget.innerHTML = `
          <strong>${businessDays} día${businessDays !== 1 ? 's' : ''} laborales</strong> serán solicitados
          <br><small>Del ${startDate.toLocaleDateString('es-ES')} al ${endDate.toLocaleDateString('es-ES')}</small>
        `
        this.calculationTarget.style.display = 'block'
      } else {
        this.textTarget.innerHTML = 'La fecha de fin debe ser posterior a la fecha de inicio'
        this.calculationTarget.style.display = 'block'
      }
    } else {
      this.calculationTarget.style.display = 'none'
    }
  }

  parseLocalDate(dateString) {
      const [year, month, day] = dateString.split('-').map(Number)
      return new Date(year, month - 1, day) // month is 0-indexed
  }

  calculateBusinessDays(startDate, endDate) {
    let count = 0
    const currentDate = new Date(startDate)
    
    while (currentDate <= endDate) {
      const dayName = currentDate.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase()
      const dateString = this.formatDateToString(currentDate)

      // Verificar si es un día laboral Y no es festivo
      if (this.countryData.working_days[dayName] === true && !this.isHoliday(dateString)) {
        count++
      }
      
      currentDate.setDate(currentDate.getDate() + 1)
    }
    
    return count
  }

  isHoliday(dateString) {
    return this.holidays && this.holidays.has(dateString)
  }

  formatDateToString(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }
}