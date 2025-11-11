require 'rails_helper'

RSpec.describe 'VacationRequests Calendar', type: :request do
  let(:country) { create(:country) }
  let(:hr_user) { create(:user, roles: { hr: true }, country: country) }
  let(:leader_user) { create(:user, roles: { leader: true }, country: country) }
  let(:employee_user) { create(:user, roles: { employee: true }, country: country) }
  let(:subordinate) { create(:user, roles: { employee: true }, country: country, lead: leader_user) }

  describe 'GET /vacation_requests/calendar' do
    context 'when user is HR' do
      before { sign_in hr_user }

      it 'allows access to calendar' do
        get calendar_vacation_requests_path
        expect(response).to have_http_status(:success)
      end

      it 'assigns current month and year by default' do
        get calendar_vacation_requests_path
        expect(assigns(:year)).to eq(Date.current.year)
        expect(assigns(:month)).to eq(Date.current.month)
      end

      it 'accepts year and month parameters' do
        get calendar_vacation_requests_path(year: 2023, month: 6)
        expect(assigns(:year)).to eq(2023)
        expect(assigns(:month)).to eq(6)
      end

      it 'shows all vacation requests' do
        vacation1 = create(:vacation_request, :taken, user: employee_user, start_date: Date.current, end_date: Date.current + 2.days)
        vacation2 = create(:vacation_request, :taken, user: subordinate, start_date: Date.current + 5.days, end_date: Date.current + 7.days)
        
        get calendar_vacation_requests_path
        expect(assigns(:vacation_requests)).to include(vacation1, vacation2)
      end
    end

    context 'when user is a leader' do
      before { sign_in leader_user }

      it 'allows access to calendar' do
        get calendar_vacation_requests_path
        expect(response).to have_http_status(:success)
      end

      it 'shows only team vacation requests' do
        team_vacation = create(:vacation_request, :taken, user: subordinate, start_date: Date.current, end_date: Date.current + 2.days)
        other_vacation = create(:vacation_request, :taken, user: employee_user, start_date: Date.current, end_date: Date.current + 2.days)
        
        get calendar_vacation_requests_path
        expect(assigns(:vacation_requests)).to include(team_vacation)
        expect(assigns(:vacation_requests)).not_to include(other_vacation)
      end

      it 'includes leader own vacations' do
        leader_vacation = create(:vacation_request, :taken, user: leader_user, start_date: Date.current, end_date: Date.current + 2.days)
        
        get calendar_vacation_requests_path
        expect(assigns(:vacation_requests)).to include(leader_vacation)
      end
    end

    context 'when user is regular employee' do
      before { sign_in employee_user }

      it 'denies access to calendar' do
        get calendar_vacation_requests_path
        expect(response).to redirect_to(vacation_requests_path)
        expect(flash[:alert]).to eq("No tienes permisos para acceder al calendario")
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to login' do
        get calendar_vacation_requests_path
        expect(response).to redirect_to(login_sessions_path)
      end
    end
  end

  describe 'calendar data organization' do
    let!(:vacation_request) do
      create(:vacation_request, :taken, 
             user: subordinate, 
             start_date: Date.current, 
             end_date: Date.current + 2.days)
    end

    before { sign_in leader_user }

    it 'organizes vacation requests by date' do
      get calendar_vacation_requests_path
      vacation_days = assigns(:vacation_days)
      
      expect(vacation_days[Date.current]).to include(vacation_request)
      expect(vacation_days[Date.current + 1.day]).to include(vacation_request)
      expect(vacation_days[Date.current + 2.days]).to include(vacation_request)
    end

    it 'calculates navigation dates correctly' do
      get calendar_vacation_requests_path(year: 2023, month: 6)
      
      expect(assigns(:prev_month)).to eq(5)
      expect(assigns(:prev_year)).to eq(2023)
      expect(assigns(:next_month)).to eq(7)
      expect(assigns(:next_year)).to eq(2023)
    end

    it 'handles year boundaries for navigation' do
      get calendar_vacation_requests_path(year: 2023, month: 1)
      
      expect(assigns(:prev_month)).to eq(12)
      expect(assigns(:prev_year)).to eq(2022)
      
      get calendar_vacation_requests_path(year: 2023, month: 12)
      
      expect(assigns(:next_month)).to eq(1)
      expect(assigns(:next_year)).to eq(2024)
    end
  end

  describe 'calendar statistics' do
    let!(:vacation1) { create(:vacation_request, :taken, user: subordinate, start_date: Date.current, end_date: Date.current + 2.days, days_requested: 3) }
    let!(:vacation2) { create(:vacation_request, :approved, user: subordinate, start_date: Date.current + 5.days, end_date: Date.current + 7.days, days_requested: 3) }

    before { sign_in leader_user }

    it 'calculates statistics correctly' do
      get calendar_vacation_requests_path
      stats = assigns(:stats)
      
      expect(stats[:total_requests]).to eq(2)
      expect(stats[:employees_on_vacation]).to eq(1) # Only one unique employee
      expect(stats[:days_requested]).to eq(6) # Total days from both requests
    end
  end
end