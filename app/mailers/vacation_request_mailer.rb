class VacationRequestMailer < ApplicationMailer
  def approved
    @name = params[:name]
    email = params[:email]
    mail(to: email, subject: "Vacaciones aprobadas")
  end
end
