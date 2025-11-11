require 'rails_helper'

RSpec.describe Country, type: :model do
  let(:country) do
    create(:country, 
           name: 'Test Country',
           vacation_term: 'vacaciones',
           default_vacation_days: 15)
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:vacation_term) }
    it { is_expected.to validate_presence_of(:default_vacation_days) }
    it { is_expected.to validate_numericality_of(:default_vacation_days).is_greater_than(0).is_less_than_or_equal_to(30) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:users).dependent(:restrict_with_error) }
  end

  describe 'working days configuration' do
    context 'when working_days is not set' do
      it 'sets default working days before save' do
        country.working_days = nil
        country.save!
        
        expect(country.working_days).to eq({
          'monday' => true,
          'tuesday' => true,
          'wednesday' => true,
          'thursday' => true,
          'friday' => true,
          'saturday' => false,
          'sunday' => false
        })
      end
    end

    context 'when working_days is already set' do
      it 'does not override existing working_days' do
        custom_working_days = {
          'monday' => true,
          'tuesday' => true,
          'wednesday' => true,
          'thursday' => true,
          'friday' => true,
          'saturday' => true,
          'sunday' => false
        }
        
        country.working_days = custom_working_days
        country.save!
        
        expect(country.working_days).to eq(custom_working_days)
      end
    end
  end

  describe '#working_day?' do
    context 'with default working days (Monday-Friday)' do
      it 'returns true for Monday' do
        monday = Date.new(2024, 9, 9) # Monday
        expect(country.working_day?(monday)).to be true
      end

      it 'returns true for Friday' do
        friday = Date.new(2024, 9, 13) # Friday
        expect(country.working_day?(friday)).to be true
      end

      it 'returns false for Saturday' do
        saturday = Date.new(2024, 9, 14) # Saturday
        expect(country.working_day?(saturday)).to be false
      end

      it 'returns false for Sunday' do
        sunday = Date.new(2024, 9, 15) # Sunday
        expect(country.working_day?(sunday)).to be false
      end
    end

    context 'with custom working days including Saturday' do
      before do
        country.working_days = {
          'monday' => true,
          'tuesday' => true,
          'wednesday' => true,
          'thursday' => true,
          'friday' => true,
          'saturday' => true,
          'sunday' => false
        }
      end

      it 'returns true for Saturday when configured as working day' do
        saturday = Date.new(2024, 9, 14) # Saturday
        expect(country.working_day?(saturday)).to be true
      end
    end
  end

  describe '#business_days_between' do
    context 'with default working days (Monday-Friday)' do
      it 'calculates 5 business days for Monday to Friday' do
        start_date = Date.new(2024, 9, 9)  # Monday
        end_date = Date.new(2024, 9, 13)   # Friday
        
        expect(country.business_days_between(start_date, end_date)).to eq(5)
      end

      it 'calculates 2 business days for Friday to Monday (excluding weekend)' do
        start_date = Date.new(2024, 9, 13) # Friday
        end_date = Date.new(2024, 9, 16)   # Monday
        
        expect(country.business_days_between(start_date, end_date)).to eq(2)
      end

      it 'calculates 0 business days for weekend only' do
        start_date = Date.new(2024, 9, 14) # Saturday
        end_date = Date.new(2024, 9, 15)   # Sunday
        
        expect(country.business_days_between(start_date, end_date)).to eq(0)
      end

      it 'calculates 5 business days for full week (Monday to Sunday)' do
        start_date = Date.new(2024, 9, 9)  # Monday
        end_date = Date.new(2024, 9, 15)   # Sunday
        
        expect(country.business_days_between(start_date, end_date)).to eq(5)
      end

      it 'returns 0 when start_date is after end_date' do
        start_date = Date.new(2024, 9, 15) # Sunday
        end_date = Date.new(2024, 9, 9)    # Monday
        
        expect(country.business_days_between(start_date, end_date)).to eq(0)
      end

      it 'calculates 1 business day for same working day' do
        date = Date.new(2024, 9, 9) # Monday
        
        expect(country.business_days_between(date, date)).to eq(1)
      end

      it 'calculates 0 business days for same non-working day' do
        date = Date.new(2024, 9, 14) # Saturday
        
        expect(country.business_days_between(date, date)).to eq(0)
      end
    end

    context 'with custom working days including Saturday' do
      before do
        country.working_days = {
          'monday' => true,
          'tuesday' => true,
          'wednesday' => true,
          'thursday' => true,
          'friday' => true,
          'saturday' => true,
          'sunday' => false
        }
      end

      it 'includes Saturday in business days calculation' do
        start_date = Date.new(2024, 9, 9)  # Monday
        end_date = Date.new(2024, 9, 14)   # Saturday
        
        expect(country.business_days_between(start_date, end_date)).to eq(6)
      end
    end
  end

  describe '#working_days_in_week' do
    it 'returns 5 for default working days (Monday-Friday)' do
      expect(country.working_days_in_week).to eq(5)
    end

    context 'with custom working days including Saturday' do
      before do
        country.working_days = {
          'monday' => true,
          'tuesday' => true,
          'wednesday' => true,
          'thursday' => true,
          'friday' => true,
          'saturday' => true,
          'sunday' => false
        }
      end

      it 'returns 6 when Saturday is included' do
        expect(country.working_days_in_week).to eq(6)
      end
    end
  end

  describe 'class methods' do
    let!(:colombia) { create(:country, name: 'Colombia') }
    let!(:mexico) { create(:country, name: 'Mexico') }

    describe '.colombia' do
      it 'returns the Colombia country' do
        expect(Country.colombia).to eq(colombia)
      end
    end

    describe '.mexico' do
      it 'returns the Mexico country' do
        expect(Country.mexico).to eq(mexico)
      end
    end
  end

  describe '#uses_rest_days?' do
    it 'returns true for Mexico' do
      mexico = create(:country, name: 'Mexico')
      expect(mexico.uses_rest_days?).to be true
    end

    it 'returns false for other countries' do
      colombia = create(:country, name: 'Colombia')
      expect(colombia.uses_rest_days?).to be false
    end
  end
end
