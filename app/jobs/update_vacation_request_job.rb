class UpdateVacationRequestJob < ApplicationJob
  queue_as :default

  def perform(*args)
    VacationRequest.approved.where("end_date < ?", Date.current).update_all(status: :taken)
    VacationRequest.taken.where("end_date > ?", Date.current).update_all(status: :approved)
  end
end
