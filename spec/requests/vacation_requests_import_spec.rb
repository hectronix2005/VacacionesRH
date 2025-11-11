require 'rails_helper'

RSpec.describe 'VacationRequests Import', type: :request do
  let(:country) { create(:country) }
  let(:hr_user) { create(:user, roles: { hr: true }, country: country) }
  let(:leader_user) { create(:user, roles: { leader: true }, country: country) }
  let(:employee_user) { create(:user, roles: { employee: true }, country: country) }
  let(:target_user) { create(:user, roles: { employee: true }, country: country, document_number: '12345678', name: 'Juan Pérez') }

  describe 'GET /vacation_requests/import' do
    context 'when user is HR' do
      before { sign_in hr_user }

      it 'allows access to import page' do
        get import_vacation_requests_path
        expect(response).to have_http_status(:success)
      end

      it 'assigns active users for reference' do
        active_user = create(:user, active: true, country: country)
        inactive_user = create(:user, active: false, country: country)
        
        get import_vacation_requests_path
        expect(assigns(:users)).to include(active_user)
        expect(assigns(:users)).not_to include(inactive_user)
      end
    end

    context 'when user is not HR or admin' do
      before { sign_in employee_user }

      it 'denies access to import page' do
        get import_vacation_requests_path
        expect(response).to redirect_to(vacation_requests_path)
        expect(flash[:alert]).to eq("No tienes permisos para importar datos")
      end
    end
  end

  describe 'POST /vacation_requests/import' do
    let(:csv_content) do
      <<~CSV
        documento,nombre,fecha_inicio,fecha_fin,dias,motivo
        12345678,Juan Pérez,2023-01-15,2023-01-29,15,Vacaciones de verano
        87654321,María González,2023-03-10,2023-03-17,8,Vacaciones familiares
      CSV
    end

    let(:csv_file) do
      temp_file = Tempfile.new(['vacation_import', '.csv'])
      temp_file.write(csv_content)
      temp_file.rewind
      
      ActionDispatch::Http::UploadedFile.new(
        tempfile: temp_file,
        filename: 'vacation_import.csv',
        type: 'text/csv'
      )
    end

    context 'when user is HR' do
      before { sign_in hr_user }

      context 'with valid CSV file' do
        before do
          # Create users that match the CSV data
          create(:user, document_number: '12345678', name: 'Juan Pérez', country: country)
          create(:user, document_number: '87654321', name: 'María González', country: country)
        end

        it 'successfully imports vacation records' do
          expect {
            post import_vacation_requests_path, params: { import_file: csv_file }
          }.to change(VacationRequest, :count).by(2)
        end

        it 'sets imported vacation requests as taken status' do
          post import_vacation_requests_path, params: { import_file: csv_file }
          
          imported_requests = VacationRequest.last(2)
          expect(imported_requests.all?(&:taken?)).to be true
        end

        it 'sets approved_by to current user' do
          post import_vacation_requests_path, params: { import_file: csv_file }
          
          imported_requests = VacationRequest.last(2)
          expect(imported_requests.all? { |r| r.approved_by == hr_user }).to be true
        end

        it 'redirects with success message' do
          post import_vacation_requests_path, params: { import_file: csv_file }
          
          expect(response).to redirect_to(vacation_requests_path)
          expect(flash[:notice]).to include("Importación exitosa: 2 registros importados")
        end

        it 'updates vacation balances for imported users' do
          user = create(:user, document_number: '12345678', name: 'Juan Pérez', country: country)
          create(:vacation_balance, user: user, year: 2023, used_days: 0)
          
          post import_vacation_requests_path, params: { import_file: csv_file }
          
          user.reload
          balance = user.vacation_balances.find_by(year: 2023)
          expect(balance.used_days).to eq(15)
        end
      end

      context 'with invalid CSV file' do
        let(:invalid_csv_content) do
          <<~CSV
            documento,nombre,fecha_inicio,fecha_fin,dias,motivo
            99999999,Usuario Inexistente,2023-01-15,2023-01-29,15,Vacaciones
          CSV
        end

        let(:invalid_csv_file) do
          temp_file = Tempfile.new(['invalid_import', '.csv'])
          temp_file.write(invalid_csv_content)
          temp_file.rewind
          
          ActionDispatch::Http::UploadedFile.new(
            tempfile: temp_file,
            filename: 'invalid_import.csv',
            type: 'text/csv'
          )
        end

        it 'does not import records for non-existent users' do
          expect {
            post import_vacation_requests_path, params: { import_file: invalid_csv_file }
          }.not_to change(VacationRequest, :count)
        end

        it 'shows error messages for failed imports' do
          post import_vacation_requests_path, params: { import_file: invalid_csv_file }
          
          expect(response).to redirect_to(import_vacation_requests_path)
          expect(flash[:alert]).to include("Error en la importación")
        end
      end

      context 'without file' do
        it 'shows error message' do
          post import_vacation_requests_path
          
          expect(response).to redirect_to(import_vacation_requests_path)
          expect(flash[:alert]).to eq("Por favor selecciona un archivo para importar")
        end
      end

      context 'with invalid file format' do
        let(:invalid_file) do
          ActionDispatch::Http::UploadedFile.new(
            tempfile: Tempfile.new(['test', '.txt']),
            filename: 'test.txt',
            type: 'text/plain'
          )
        end

        it 'shows error message for invalid format' do
          post import_vacation_requests_path, params: { import_file: invalid_file }
          
          expect(response).to redirect_to(import_vacation_requests_path)
          expect(flash[:alert]).to eq("Por favor sube un archivo CSV o Excel")
        end
      end
    end

    context 'when user is not HR or admin' do
      before { sign_in employee_user }

      it 'denies access to import functionality' do
        post import_vacation_requests_path, params: { import_file: csv_file }
        
        expect(response).to redirect_to(vacation_requests_path)
        expect(flash[:alert]).to eq("No tienes permisos para importar datos")
      end
    end
  end

  describe 'user matching logic' do
    let(:csv_content_with_name_only) do
      <<~CSV
        documento,nombre,fecha_inicio,fecha_fin,dias,motivo
        ,Juan Pérez,2023-01-15,2023-01-29,15,Vacaciones de verano
      CSV
    end

    let(:csv_file_name_only) do
      temp_file = Tempfile.new(['name_only_import', '.csv'])
      temp_file.write(csv_content_with_name_only)
      temp_file.rewind
      
      ActionDispatch::Http::UploadedFile.new(
        tempfile: temp_file,
        filename: 'name_only_import.csv',
        type: 'text/csv'
      )
    end

    before { sign_in hr_user }

    it 'matches users by document number when available' do
      user = create(:user, document_number: '12345678', name: 'Different Name', country: country)
      
      post import_vacation_requests_path, params: { import_file: csv_file }
      
      imported_request = VacationRequest.last
      expect(imported_request.user).to eq(user)
    end

    it 'matches users by name when document is not available' do
      user = create(:user, name: 'Juan Pérez', country: country)
      
      post import_vacation_requests_path, params: { import_file: csv_file_name_only }
      
      imported_request = VacationRequest.last
      expect(imported_request.user).to eq(user)
    end
  end

  describe 'CSV validation' do
    before { sign_in hr_user }

    context 'with invalid date format' do
      let(:invalid_date_csv) do
        <<~CSV
          documento,nombre,fecha_inicio,fecha_fin,dias,motivo
          12345678,Juan Pérez,invalid-date,2023-01-29,15,Vacaciones
        CSV
      end

      let(:invalid_date_file) do
        temp_file = Tempfile.new(['invalid_date', '.csv'])
        temp_file.write(invalid_date_csv)
        temp_file.rewind
        
        ActionDispatch::Http::UploadedFile.new(
          tempfile: temp_file,
          filename: 'invalid_date.csv',
          type: 'text/csv'
        )
      end

      it 'handles date parsing errors gracefully' do
        create(:user, document_number: '12345678', name: 'Juan Pérez', country: country)
        
        expect {
          post import_vacation_requests_path, params: { import_file: invalid_date_file }
        }.not_to change(VacationRequest, :count)
        
        expect(flash[:alert]).to include("Error en la importación")
      end
    end
  end
end