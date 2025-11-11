require 'prawn'
require 'prawn/table'

class VacationRequestPdfGenerator
  def initialize(vacation_request)
    @vacation_request = vacation_request
    @user = vacation_request.user
  end

  def generate
    # Silenciar advertencia sobre fuentes internacionales
    Prawn::Fonts::AFM.hide_m17n_warning = true

    Prawn::Document.new(page_size: 'A4', margin: [ 50, 50, 50, 50 ]) do |pdf|
      # Header
      pdf.font_size 18
      pdf.text "Solicitud de #{@user.vacation_term.capitalize}", style: :bold, align: :center
      pdf.move_down 20

      # Información del empleado
      pdf.font_size 12
      pdf.text "Información del Empleado", style: :bold
      pdf.move_down 10

      employee_data = [
        [ "Nombre:", @user.name ],
        [ "Email:", @user.email ],
        [ "Área:", @user.area&.name || "N/A" ],
        [ "País:", @user.country&.name || "N/A" ],
        [ "Empresa:", @user.company || "N/A" ]
      ]

      pdf.table(employee_data,
                column_widths: [ 120, 350 ],
                cell_style: { border_width: 0, padding: [ 2, 5 ] }) do
        column(0).font_style = :bold
      end

      pdf.move_down 20

      # Información de la solicitud
      pdf.text "Detalles de la Solicitud", style: :bold
      pdf.move_down 10

      request_data = [
        [ "Empresa:", @vacation_request.company || "N/A" ],
        [ "Fecha de Inicio:", @vacation_request.start_date.strftime("%d/%m/%Y") ],
        [ "Fecha de Fin:", @vacation_request.end_date.strftime("%d/%m/%Y") ],
        [ "Días Solicitados:", @vacation_request.days_requested.to_s ],
        [ "Estado:", status_in_spanish(@vacation_request.status) ],
        [ "Fecha de Solicitud:", @vacation_request.created_at.strftime("%d/%m/%Y %H:%M") ]
      ]

      if @vacation_request.reason.present?
        request_data << [ "Motivo:", @vacation_request.reason ]
      end

      if @vacation_request.approved_by.present?
        request_data << [ "Aprobado por:", @vacation_request.approved_by.name ]
        request_data << [ "Fecha de Aprobación:", @vacation_request.updated_at.strftime("%d/%m/%Y %H:%M") ]
      end

      if @vacation_request.rejected_reason.present?
        request_data << [ "Motivo de Rechazo:", @vacation_request.rejected_reason ]
      end

      pdf.table(request_data,
                column_widths: [ 120, 350 ],
                cell_style: { border_width: 0, padding: [ 2, 5 ] }) do
        column(0).font_style = :bold
      end

      # Información de aprobaciones
      if @vacation_request.vacation_approvals.any?
        pdf.move_down 20
        pdf.text "Aprobaciones", style: :bold
        pdf.move_down 10

        @vacation_request.vacation_approvals.each_with_index do |approval, index|
          approval_data = [
            [ "Aprobador #{index + 1}:", approval.user.name ],
            [ "Rol:", approval.role_display_name || "N/A" ],
            [ "Estado:", status_in_spanish(approval.status) ]
          ]

          if approval.approved_at.present?
            approval_data << [ "Fecha de Aprobación:", approval.approved_at.strftime("%d/%m/%Y %H:%M") ]
          end

          if approval.comments.present?
            approval_data << [ "Comentarios:", approval.comments ]
          end

          pdf.table(approval_data,
                    column_widths: [ 120, 350 ],
                    cell_style: { border_width: 0, padding: [ 2, 5 ] }) do
            column(0).font_style = :bold
          end

          # Añadir separación entre aprobaciones si hay más de una
          pdf.move_down 10 if index < @vacation_request.vacation_approvals.count - 1
        end
      end

      # Footer
      pdf.move_down 50
      pdf.font_size 10
      pdf.text "Documento generado automáticamente el #{Date.current.strftime('%d/%m/%Y')}",
               align: :center, style: :italic

      # Número de página
      pdf.number_pages "Página <page> de <total>",
                       at: [ pdf.bounds.right - 50, 0 ],
                       align: :right,
                       size: 10
    end
  end

  def filename
    sanitized_name = @user.name.gsub(/[^0-9A-Za-z.\-]/, '_')
    year = @vacation_request.start_date.year
    "#{sanitized_name}_#{year}_#{@vacation_request.id}.pdf"
  end

  private

  def status_in_spanish(status)
    case status
    when 'pending'
      'Pendiente'
    when 'approved'
      'Aprobada'
    when 'rejected'
      'Rechazada'
    when 'taken'
      'Tomada'
    else
      status.capitalize
    end
  end
end
