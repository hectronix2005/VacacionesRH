# Project Guidelines - PicapRh

## Project Overview

**PicapRh** is a comprehensive Ruby on Rails 8.0.2 vacation management system designed for Colombian and Mexican companies. The system handles multi-level approval workflows for vacation requests, supports different vacation terminology by country (vacaciones vs días de descanso), and provides role-based access control for employees, leaders, and HR personnel.

### Key Features
- **Multi-Approval Workflow**: Requires both leader and HR approval for vacation requests
- **Country-Specific Support**: Colombia (vacaciones) and Mexico (días de descanso) with different terminology
- **Role-Based Access Control**: Employee, Leader, and HR roles with specific permissions
- **Comprehensive Dashboard**: Role-specific dashboards with statistics and pending actions
- **Vacation Balance Management**: Track available, used, and remaining vacation days
- **Pagination System**: Efficient pagination using Pagy gem for large datasets
- **Modern JavaScript**: Stimulus controllers for interactive features without inline JavaScript
- **Responsive Design**: Mobile-first TailwindCSS implementation

### Technology Stack
- **Framework**: Ruby on Rails 8.0.2
- **Database**: SQLite3 (development/test), supports production databases via configuration
- **Frontend**: Modern Rails stack with Hotwire (Turbo + Stimulus), Importmap for JavaScript
- **CSS Framework**: TailwindCSS v4 with tailwindcss-rails gem
- **Asset Pipeline**: Propshaft (modern replacement for Sprockets)
- **Web Server**: Puma
- **Caching**: Solid Cache (database-backed)
- **Background Jobs**: Solid Queue (database-backed)
- **Real-time**: Solid Cable (database-backed Action Cable)
- **Deployment**: Docker with Kamal deployment tool
- **Performance**: Thruster for HTTP caching/compression
- **Authentication**: BCrypt for secure password hashing
- **Pagination**: Pagy v8.6.3 for efficient pagination with Spanish localization

## Project Structure

This follows standard Rails 8.0 directory structure:

- **app/**: Main application code
  - `controllers/`: MVC controllers with concerns
  - `models/`: ActiveRecord models with concerns  
  - `views/`: ERB templates and layouts
  - `helpers/`: View helpers
  - `jobs/`: Background job classes
  - `mailers/`: Email handling
  - `javascript/`: Stimulus controllers and JS modules
  - `assets/`: Images and stylesheets
- **config/**: Application configuration files
- **db/**: Database migrations and schema
- **spec/**: RSpec test suite (models, controllers, system, integration)
- **lib/**: Custom libraries and tasks
- **public/**: Static assets served directly
- **bin/**: Executable scripts
- **Dockerfile**: Container configuration

## Testing Guidelines

### Test Framework
- Uses **RSpec** testing framework for Rails
- **System tests**: Capybara + Selenium WebDriver for browser testing
- **Unit tests**: RSpec with FactoryBot for test data
- **Additional gems**: DatabaseCleaner, Shoulda Matchers

### Running Tests
```bash
# Run all specs
bundle exec rspec

# Run specific test types
bundle exec rspec spec/models
bundle exec rspec spec/controllers
bundle exec rspec spec/system
bundle exec rspec spec/requests

# Run specific spec file
bundle exec rspec spec/models/user_spec.rb

# Run with documentation format or other options
bundle exec rspec --format documentation
bundle exec rspec --tag focus
```

### Test Requirements
- **Always run specs** after making changes to verify correctness
- **System specs** should pass for UI changes
- **Model specs** should cover validations and business logic
- **Request specs** should verify controller actions and routing
- **Use FactoryBot** for test data generation instead of fixtures

## Build and Deployment

### Local Development
```bash
# Setup
bundle install
rails db:create db:migrate
bin/dev                     # Start development server with TailwindCSS watch

# Alternative: run separately
rails server                # Start development server
rails tailwindcss:watch     # Watch and compile TailwindCSS changes

# Database operations
rails db:migrate
rails db:seed
rails db:reset
```

### Production Deployment
- **Containerized**: Uses Docker with optimized Dockerfile
- **Deployment Tool**: Kamal for zero-downtime deployments
- **Build process**: Standard Rails asset precompilation

### Pre-deployment Checklist
1. Run full test suite: `bundle exec rspec`
2. Run security scan: `bundle exec brakeman`
3. Run code style check: `bundle exec rubocop`
4. Verify database migrations work: `rails db:migrate:status`

## Code Style Guidelines

### Ruby Style
- **Linter**: RuboCop with Rails Omakase configuration
- **Run linter**: `bundle exec rubocop`
- **Auto-fix**: `bundle exec rubocop -a`

### Standards
- Follow **Rails conventions** and idioms
- Use **Hotwire patterns** (Turbo/Stimulus) over heavy JavaScript
- **RESTful routes** and standard CRUD operations
- **Strong parameters** for controller inputs
- **Model validations** and proper ActiveRecord associations

### CSS and Styling
- **CSS Framework**: TailwindCSS v4 for utility-first styling
- **Custom styles**: Add in `app/assets/tailwind/application.css`
- **Build process**: TailwindCSS automatically compiles with `bin/dev`
- **Responsive design**: Use Tailwind's responsive utilities (sm:, md:, lg:, xl:)
- **Component organization**: Create reusable view partials with consistent Tailwind classes

### TailwindCSS Stimulus Components
- **Library**: tailwindcss-stimulus-components for pre-built interactive components
- **Installation**: Added via importmap with CDN URL
- **Usage**: Import specific components in JavaScript controllers as needed
- **Components Available**: Dropdown, Modal, Tabs, Toggle, Slideover, and more
- **Documentation**: Refer to https://github.com/excid3/tailwindcss-stimulus-components for component usage

### Security
- **Brakeman scanner** for security vulnerabilities
- Always use **strong parameters** in controllers
- Proper **authorization checks** before actions
- **CSRF protection** enabled by default

## Development Workflow

1. **Create feature branch** from main
2. **Write tests first** (TDD approach recommended)  
3. **Implement feature** following Rails conventions
4. **Run tests**: `bundle exec rspec`
5. **Check code style**: `bundle exec rubocop`
6. **Security scan**: `bundle exec brakeman`
7. **Submit for review** with passing tests

## Key Commands for Junie

```bash
# Essential development commands
bundle exec rspec            # Run all tests
bundle exec rspec spec/system # Run browser/integration tests
bundle exec rubocop          # Code style check
bundle exec brakeman         # Security scan
rails server                 # Start development server
rails console               # Rails console for debugging
rails db:migrate            # Run database migrations
bin/dev                     # Start development server with TailwindCSS watch
rails tailwindcss:build    # Build TailwindCSS (one-time)
rails tailwindcss:watch    # Watch and rebuild TailwindCSS on changes
```

## Notes for Junie
<!-- - **Always run tests** before submitting changes -->
- **Follow Rails conventions** - this is a standard Rails 8.0 app
- **Use Hotwire** (Turbo/Stimulus) for dynamic behavior instead of complex JavaScript
- **Security first** - run Brakeman scans for security-sensitive changes
- **Database changes** require migrations - never edit schema.rb directly
