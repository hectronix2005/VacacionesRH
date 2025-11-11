# Vacation Management System Seeds
# This file creates test data for the vacation management system

puts "🌱 Creating seed data for Vacation Management System..."

# Create default vacation approval configuration
VacationApprovalConfig.setup_default_config!

Country.find_or_create_by!(
  { name: 'Colombia', vacation_term: 'vacaciones', default_vacation_days: 15 }
)
Country.find_or_create_by!(
  { name: 'Mexico', vacation_term: 'días de descanso', default_vacation_days: 12 }
)

# HR Users (can manage everything)
puts "Creating users..."
admin = User.create(
  document_number: "1",
  name: "Admin",
  email: "admin@gmail.com",
  phone: "+57-300-123-4567",
  country: Country.find_by(name: "Colombia"),
  admin: true,
  leader: true,
  password: "adm1n123",
  active: true,
  hire_date: 3.years.ago
)
admin.lead = admin
admin.save

User.find_or_create_by!(document_number: "1010221092") do |u|
  u.name = "Ginna Ladino"
  u.email = "gladino@picap.co"
  u.phone = "+57-300-123-4567"
  u.country = Country.find_by(name: "Colombia")
  u.hr = true
  u.password = "123456"
  u.active = true
  u.hire_date = 3.years.ago
end

# Usuarios de prueba según README - Colombia
colombia = Country.find_by(name: "Colombia")
mexico = Country.find_by(name: "Mexico")

# HR Colombia
hr_col = User.find_or_create_by!(document_number: "12345678") do |u|
  u.name = "HR Colombia"
  u.email = "hr.colombia@picap.co"
  u.phone = "+57-300-123-4567"
  u.country = colombia
  u.hr = true
  u.password = "password123"
  u.password_confirmation = "password123"
  u.active = true
  u.hire_date = 3.years.ago
end
hr_col.lead = hr_col
hr_col.save

# Líder Colombia
leader_col = User.find_or_create_by!(document_number: "87654321") do |u|
  u.name = "Líder Colombia"
  u.email = "leader.colombia@picap.co"
  u.phone = "+57-300-123-4568"
  u.country = colombia
  u.leader = true
  u.employee = true
  u.password = "password123"
  u.password_confirmation = "password123"
  u.active = true
  u.hire_date = 2.years.ago
  u.lead = hr_col
end

# Empleado Colombia
employee_col = User.find_or_create_by!(document_number: "11223344") do |u|
  u.name = "Empleado Colombia"
  u.email = "empleado.colombia@picap.co"
  u.phone = "+57-300-123-4569"
  u.country = colombia
  u.employee = true
  u.password = "password123"
  u.password_confirmation = "password123"
  u.active = true
  u.hire_date = 1.year.ago
  u.lead = leader_col
end

# HR México
hr_mex = User.find_or_create_by!(document_number: "CURP123456") do |u|
  u.name = "HR México"
  u.email = "hr.mexico@picap.co"
  u.phone = "+52-55-1234-5678"
  u.country = mexico
  u.hr = true
  u.password = "password123"
  u.password_confirmation = "password123"
  u.active = true
  u.hire_date = 3.years.ago
end
hr_mex.lead = hr_mex
hr_mex.save

# Líder México
leader_mex = User.find_or_create_by!(document_number: "CURP789012") do |u|
  u.name = "Líder México"
  u.email = "leader.mexico@picap.co"
  u.phone = "+52-55-1234-5679"
  u.country = mexico
  u.leader = true
  u.employee = true
  u.password = "password123"
  u.password_confirmation = "password123"
  u.active = true
  u.hire_date = 2.years.ago
  u.lead = hr_mex
end

# Empleado México
employee_mex = User.find_or_create_by!(document_number: "CURP345678") do |u|
  u.name = "Empleado México"
  u.email = "empleado.mexico@picap.co"
  u.phone = "+52-55-1234-5680"
  u.country = mexico
  u.employee = true
  u.password = "password123"
  u.password_confirmation = "password123"
  u.active = true
  u.hire_date = 1.year.ago
  u.lead = leader_mex
end

puts "✅ Datos semilla creados exitosamente"
puts "- Países disponibles: #{Country.count}"
puts "- Configuraciones de aprobación: #{VacationApprovalConfig.count}"
puts "- Usuarios creados: #{User.count}"
