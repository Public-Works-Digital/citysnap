# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project: Citysnap

A Rails 8.0.3 application for city issue reporting with photo attachments. Users can authenticate, create issues with photos, and manage their reported issues.

## Development Commands

### Initial Setup
```bash
bin/setup  # Installs dependencies, prepares database, and starts dev server
```

### Development Server
```bash
bin/dev  # Starts Rails server (port 3000) and TailwindCSS watcher via Foreman
```

### Database Operations
```bash
bin/rails db:create     # Create database
bin/rails db:migrate    # Run pending migrations
bin/rails db:seed       # Load seed data
bin/rails db:prepare    # Setup database from scratch
```

### Testing
```bash
bin/rails test                    # Run all tests
bin/rails test test/models/       # Run model tests
bin/rails test test/system/       # Run system tests
bin/rails test:system             # Run system tests with browser
```

### Code Quality
```bash
bin/rubocop          # Run Ruby style checker
bin/brakeman         # Security vulnerability scanner
```

### Rails Console
```bash
bin/rails console    # Interactive Rails console
bin/rails c          # Shorthand for console
```

## Architecture Overview

### Core Models
- **User** (app/models/user.rb): Devise-based authentication with has_many :issues
- **Issue** (app/models/issue.rb): User-reported issues with photo attachments via ActiveStorage

### Authentication
Uses Devise 4.9 with standard modules (database_authenticatable, registerable, recoverable, rememberable, validatable)

### Key Technologies
- **Frontend**: Hotwire (Turbo + Stimulus) with TailwindCSS
- **Asset Pipeline**: Propshaft with Import Maps
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable
- **Database**: SQLite3 (development)
- **Deployment**: Kamal-ready with Docker support

### ClaudeOnRails Integration

This project uses ClaudeOnRails with specialized agents defined in `claude-swarm.yml`:
- **architect**: Main coordinator for full-stack development
- **models**: ActiveRecord and database specialist
- **controllers**: Request handling and routing
- **views**: UI templates and layouts
- **stimulus**: JavaScript controllers and Turbo
- **jobs**: Background job processing
- **tests**: Minitest testing
- **devops**: Deployment and configuration

Review `.claude-on-rails/context.md` for development guidelines.

### Current Implementation Notes

The Issues controller (app/controllers/issues_controller.rb:69) has a comment "# FIX: Help" indicating the strong parameters need attention. The controller uses Rails 8's new `params.expect` syntax for parameter handling.

### Rails 8 Specific Features
- Uses `params.expect` for strong parameters (new in Rails 8)
- Solid suite (Cache, Queue, Cable) for production-ready setup
- Thruster for HTTP asset caching/compression