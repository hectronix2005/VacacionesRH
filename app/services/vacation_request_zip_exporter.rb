require 'zip'
require 'tempfile'

class VacationRequestZipExporter
  def initialize(vacation_requests)
    @vacation_requests = vacation_requests
  end

  def generate
    # Crear un archivo temporal para el ZIP
    temp_file = Tempfile.new(['vacation_requests', '.zip'])
    temp_file.binmode

    begin
      Zip::OutputStream.open(temp_file.path) do |zipfile|
        @vacation_requests.each do |request|
          # Generar PDF para cada solicitud
          pdf_generator = VacationRequestPdfGenerator.new(request)
          pdf_content = pdf_generator.generate.render

          # Agregar el PDF al ZIP
          zipfile.put_next_entry(pdf_generator.filename)
          zipfile.write(pdf_content)
        end
      end

      # Leer el contenido del archivo ZIP
      temp_file.rewind
      zip_content = temp_file.read

      return zip_content
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def filename
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    "solicitudes_vacaciones_#{timestamp}.zip"
  end

  def self.generate_for_requests(vacation_requests)
    exporter = new(vacation_requests)
    {
      content: exporter.generate,
      filename: exporter.filename,
      content_type: 'application/zip'
    }
  end
end
