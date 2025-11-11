class RecalculateBalancesJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "Iniciando recálculo de balances de vacaciones..."

    year = Date.current.year
    puts "Año a procesar: #{year}"

    # Actualizar balances existentes
    puts "Actualizando balances existentes..."
    VacationBalanceCalculator.update_all_balances

    # Crear balances faltantes
    puts "Creando balances faltantes..."
    VacationBalanceCalculator.create_missing_balances

    puts "¡Recálculo completado!"
  end
end
