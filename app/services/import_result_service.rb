class ImportResultService
  TEMP_DIR = Rails.root.join('tmp', 'import_results')
  EXPIRY_TIME = 1.hour

  def self.create_result_file(user_id, import_type, results)
    ensure_temp_directory_exists

    filename = "#{import_type}_import_#{user_id}_#{Time.current.to_i}.txt"
    filepath = TEMP_DIR.join(filename)

    content = generate_content(import_type, results)

    File.write(filepath, content)

    # Store result info in session or cache for later retrieval
    result_info = {
      filename: filename,
      filepath: filepath.to_s,
      created_at: Time.current,
      expires_at: Time.current + EXPIRY_TIME,
      import_type: import_type,
      user_id: user_id
    }

    Rails.cache.write("import_result_#{user_id}_#{filename}", result_info, expires_in: EXPIRY_TIME)

    filename
  end

  def self.get_result_file(user_id, filename)
    cache_key = "import_result_#{user_id}_#{filename}"
    result_info = Rails.cache.read(cache_key)

    return nil unless result_info
    return nil if result_info[:expires_at] < Time.current
    return nil unless File.exist?(result_info[:filepath])

    result_info
  end

  def self.cleanup_expired_files
    return unless Dir.exist?(TEMP_DIR)

    Dir.glob(TEMP_DIR.join('*')).each do |file|
      if File.mtime(file) < EXPIRY_TIME.ago
        File.delete(file)
      end
    end
  end

  private

  def self.ensure_temp_directory_exists
    FileUtils.mkdir_p(TEMP_DIR) unless Dir.exist?(TEMP_DIR)
  end

  def self.generate_content(import_type, results)
    content = []
    content << "="*60
    content << "REPORTE DE IMPORTACIÓN - #{import_type.upcase}"
    content << "="*60
    content << "Fecha: #{Time.current.strftime('%d/%m/%Y %H:%M:%S')}"
    content << ""

    if results[:success]
      content << "✅ IMPORTACIÓN EXITOSA"
      content << ""
      content << "Estadísticas:"

      if import_type == 'usuarios'
        content << "- Usuarios creados: #{results[:imported] || 0}"
        content << "- Usuarios actualizados: #{results[:updated] || 0}"
        content << "- Total procesados: #{(results[:imported] || 0) + (results[:updated] || 0)}"
      else
        content << "- Registros importados: #{results[:imported] || 0}"
        content << "- Total procesados: #{results[:imported] || 0}"
      end

    else
      content << "❌ IMPORTACIÓN CON ERRORES"
      content << ""
      content << "Estadísticas:"

      if import_type == 'usuarios'
        content << "- Usuarios creados: #{results[:imported] || 0}"
        content << "- Usuarios actualizados: #{results[:updated] || 0}"
        content << "- Errores encontrados: #{results[:errors]&.length || 0}"
      else
        content << "- Registros importados: #{results[:imported] || 0}"
        content << "- Errores encontrados: #{results[:errors]&.length || 0}"
      end

      content << ""
      content << "DETALLES DE ERRORES:"
      content << "-" * 40

      if results[:errors]&.any?
        results[:errors].each do |error|
          content << "• #{error}"
        end
      end
    end

    content << ""
    content << "="*60
    content << "Este archivo expira el: #{(Time.current + EXPIRY_TIME).strftime('%d/%m/%Y %H:%M:%S')}"
    content << "="*60

    content.join("\n")
  end
end
