# ChatGPT v2.0 - Project Handoff Document

**Date:** November 18, 2024  
**Status:** Phase 2 Complete - Core Backend Services  
**Next Phase:** Phase 3 - API Endpoints

---

## Project Overview

Complete overhaul of ChatGPT CLI application into a modern web application:
- **Backend:** Sinatra (Ruby) + PostgreSQL + Sequel ORM
- **Frontend:** React + TypeScript + Vite (to be implemented)
- **Architecture:** RESTful API with separation of concerns
- **Repository:** https://github.com/jcf608/chatgpt2_0

### Key Architecture Decisions

1. **Provider Architecture:**
   - **Venice.ai**: Primary/default provider for chat completions and system prompts
   - **OpenAI**: Used EXCLUSIVELY for text-to-speech (always, regardless of chat provider)
   - System prompts → Venice.ai (or selected chat provider)
   - Chat completions → Venice.ai (default) or OpenAI (optional)
   - Text-to-speech → OpenAI (always)

2. **Code Organization (per PRINCIPLES.md):**
   - DRY: Common patterns in base classes
   - Keep files short: 5-15 lines per method
   - Single Responsibility: One purpose per class
   - No hardcoding: Discover from configuration
   - Fail fast: No fallbacks, clear error messages
   - Lazy loading: API keys loaded on demand

---

## Current Project Structure

```
chatgpt2_0/
├── PRINCIPLES.md                    # Architectural principles (READ THIS!)
├── IMPLEMENTATION_PLAN.md          # Complete 8-phase implementation plan
├── FEATURE_ANALYSIS.md             # Comprehensive feature inventory
├── HANDOFF.md                      # This document
├── .gitignore                      # Git ignore rules
│
├── backend/                        # Sinatra application
│   ├── .env                       # API keys (NOT in git)
│   ├── .env.example               # Example environment file
│   ├── Gemfile                    # Ruby dependencies
│   ├── config.ru                  # Rack configuration
│   ├── app.rb                     # Main Sinatra application
│   ├── config/
│   │   ├── database.rb            # Database connection
│   │   └── environment.rb         # Environment setup
│   ├── models/
│   │   └── base_model.rb          # Base class for Sequel models
│   ├── services/
│   │   ├── base_service.rb        # Base class for services
│   │   ├── chat_service.rb        # Chat management
│   │   ├── ai_service.rb          # AI provider factory
│   │   ├── tts_service.rb         # Text-to-speech (OpenAI)
│   │   └── prompt_service.rb      # Prompt management
│   ├── lib/
│   │   └── api_clients/
│   │       ├── base_client.rb     # Base API client
│   │       ├── venice_client.rb    # Venice.ai client
│   │       └── openai_client.rb   # OpenAI client (TTS only)
│   ├── api/                       # API endpoints (TO BE IMPLEMENTED)
│   ├── db/
│   │   └── migrations/            # Database migrations (TO BE IMPLEMENTED)
│   └── spec/                      # RSpec tests (TO BE IMPLEMENTED)
│
├── frontend/                       # React application (TO BE IMPLEMENTED)
│
├── script/
│   └── utilities/
│       └── migrate_api_keys.rb    # API key migration script
│
└── chatgpt1_0/                    # Old codebase (reference only, not in git)
```

---

## Completed Work

### Phase 1: Foundation Setup ✅

**Completed:**
- [x] Created backend directory structure
- [x] Set up Sinatra application (`app.rb`, `config.ru`)
- [x] Configured database connection (`config/database.rb`)
- [x] Set up environment configuration (`config/environment.rb`)
- [x] Created `Gemfile` with all dependencies
- [x] Created API key migration script (`script/utilities/migrate_api_keys.rb`)
- [x] Migrated API keys from old codebase to `.env` file
- [x] Created `.gitignore` to exclude sensitive files
- [x] Set up CORS configuration
- [x] Created health check endpoint (`/`)

**Key Files:**
- `backend/app.rb` - Main Sinatra application
- `backend/config/environment.rb` - Environment setup
- `backend/config/database.rb` - Database connection (PostgreSQL)
- `backend/.env` - API keys (OpenAI, Venice) - **NOT in git**

### Phase 2: Core Backend Services ✅

**Completed:**
- [x] Created `BaseModel` class (Sequel model base)
- [x] Created `BaseService` class (service object base)
- [x] Created `BaseApiClient` class (API client base)
- [x] Refactored `VeniceClient` (primary chat provider)
- [x] Refactored `OpenAIClient` (TTS only, no chat)
- [x] Created `ChatService` (chat management)
- [x] Created `AIService` (factory pattern, extended dialogue)
- [x] Created `TTSService` (text-to-speech with intelligent chunking)
- [x] Created `PromptService` (prompt management, synopsis generation)

**Key Files:**
- `backend/models/base_model.rb` - Base for all models
- `backend/services/base_service.rb` - Base for all services
- `backend/lib/api_clients/base_client.rb` - Base for API clients
- `backend/lib/api_clients/venice_client.rb` - Venice.ai integration
- `backend/lib/api_clients/openai_client.rb` - OpenAI TTS integration
- `backend/services/chat_service.rb` - Chat operations
- `backend/services/ai_service.rb` - AI provider factory
- `backend/services/tts_service.rb` - Text-to-speech service
- `backend/services/prompt_service.rb` - Prompt management

**Key Features Implemented:**
- Extended dialogue generation (multi-segment, word count tracking)
- Continue conversation (add words to existing)
- Intelligent TTS chunking (prefers punctuation boundaries)
- Prompt synopsis generation (using Venice.ai)
- Opening lines support
- Venice-specific parameters (`include_venice_system_prompt: false`)

---

## Next Steps: Phase 3 - API Endpoints

### Priority Tasks

1. **Create Database Models:**
   - `Chat` model (id, title, system_prompt_id, api_provider, voice, timestamps)
   - `Message` model (id, chat_id, role, content, sequence_number, timestamps)
   - `Prompt` model (id, name, content, timestamps)
   - `SystemPrompt` model (id, name, content, is_base, timestamps)
   - `AudioOutput` model (id, chat_id, file_path, voice, word_count, duration, timestamps)
   - `Image` model (id, chat_id, prompt_id, file_path, provider, prompt_used, timestamps)
   - `OpeningLine` model (id, prompt_name, line_text, sequence_number, timestamps)

2. **Create Database Migrations:**
   - Use Sequel migrations
   - Set up foreign keys
   - Add indexes for performance
   - Create seed data script

3. **Create Base API Class:**
   - JSON response formatting
   - Error handling middleware
   - Request validation
   - Standardized error/success response format

4. **Implement API Endpoints:**
   ```
   GET    /api/v1/chats              # List all chats
   POST   /api/v1/chats              # Create new chat
   GET    /api/v1/chats/:id          # Get chat details
   DELETE /api/v1/chats/:id          # Delete chat
   
   GET    /api/v1/chats/:id/messages # Get chat messages
   POST   /api/v1/chats/:id/messages # Add message to chat
   
   POST   /api/v1/chats/:id/send     # Send message to AI
   
   POST   /api/v1/chats/:id/extend   # Extended dialogue generation
   POST   /api/v1/chats/:id/continue # Continue conversation
   GET    /api/v1/chats/:id/word-count # Get word count
   
   GET    /api/v1/prompts            # List all prompts
   POST   /api/v1/prompts            # Create prompt
   GET    /api/v1/prompts/:id        # Get prompt
   PUT    /api/v1/prompts/:id        # Update prompt
   DELETE /api/v1/prompts/:id        # Delete prompt
   
   GET    /api/v1/opening-lines      # List opening lines
   POST   /api/v1/chats/:id/opening  # Start chat with opening line
   
   POST   /api/v1/chats/:id/audio    # Generate audio from chat
   GET    /api/v1/audio/:id          # Get audio file
   
   POST   /api/v1/chats/:id/images   # Generate images from chat
   GET    /api/v1/images/:id         # Get image file
   
   POST   /api/v1/chats/:id/synopsis # Generate prompt synopsis
   ```

5. **Update Services to Use Models:**
   - Update `ChatService` to use `Chat` and `Message` models
   - Update `PromptService` to use `Prompt` and `SystemPrompt` models
   - Remove placeholder returns

---

## Important Implementation Notes

### API Key Management

- **Location:** `backend/.env` (NOT in git)
- **Migration:** Run `ruby script/utilities/migrate_api_keys.rb` to copy from old codebase
- **Environment Variables:**
  - `OPENAI_API_KEY` - For TTS (required)
  - `VENICE_API_KEY` - For chat (required)
  - `DATABASE_URL` - PostgreSQL connection string
  - `RACK_ENV` - Environment (development/test/production)
  - `PORT` - Server port (default: 4567)

### Database Setup

**Not Yet Implemented - Next Priority:**

1. Create PostgreSQL database:
   ```bash
   createdb chatgpt2_0_development
   createdb chatgpt2_0_test
   ```

2. Install Sequel migration tool or create manual migrations

3. Create migrations for all tables (see IMPLEMENTATION_PLAN.md section 1.3)

4. Run migrations:
   ```bash
   cd backend
   # TBD: Migration command
   ```

### Service Usage Patterns

**ChatService:**
```ruby
service = ChatService.new(chat_id)
chat = service.create(title: "My Chat", api_provider: 'venice')
service.add_message(role: 'user', content: 'Hello')
messages = service.get_messages
word_count = service.word_count
```

**AIService:**
```ruby
ai = AIService.new(provider: 'venice') # Default
response = ai.send_message(messages)

# Extended dialogue
result = ai.generate_extended_dialogue(
  messages,
  target_words: 2000,
  progress_callback: ->(seg, words, total, target) {
    puts "Progress: #{total}/#{target} words"
  }
)
```

**TTSService:**
```ruby
tts = TTSService.new(voice: 'echo')
audio_path = tts.generate_audio(text)
audio_path = tts.process_chat_file(chat_content)
```

**PromptService:**
```ruby
prompt_service = PromptService.new
base = prompt_service.load_base_prompt
user_prompt = prompt_service.load_user_prompt('my_prompt')
combined = prompt_service.combine_prompts(base_prompt: base, user_prompt: user_prompt)
synopsis = prompt_service.generate_synopsis(conversation_messages)
```

### Error Handling Pattern

All services extend `BaseService` which provides:
- `handle_error(error, context)` - Centralized error handling
- `validate_presence(value, field_name)` - Validation helpers
- `logger` - Logging instance

**Example:**
```ruby
def some_method
  validate_presence(@chat_id, 'chat_id')
  # ... do work ...
rescue StandardError => e
  handle_error(e, operation: 'Some operation')
end
```

### API Client Pattern

All API clients extend `BaseApiClient` which provides:
- `post_request(url, headers, payload)` - POST with retry logic
- `get_request(url, headers)` - GET with retry logic
- Automatic error parsing
- Timeout handling

**Venice Client:**
```ruby
client = VeniceClient.new
response = client.chat_completion(messages, model: 'llama-3.3-70b')
```

**OpenAI Client (TTS only):**
```ruby
client = OpenAIClient.new
audio_data = client.text_to_speech(text, voice: 'echo')
```

---

## Testing Status

**Not Yet Implemented**

- RSpec setup needed
- Test database configuration needed
- Model tests needed
- Service tests needed
- API endpoint tests needed

**When implementing tests:**
- Follow PRINCIPLES.md section 11 (Testing & Quality)
- Test at reasonable increments
- Save test results to files
- Never commit with known errors
- Target: 80% code coverage

---

## Frontend Status

**Not Yet Implemented**

- React + TypeScript setup needed
- Vite configuration needed
- Tailwind CSS setup needed
- Component structure needed
- API client setup needed

**When implementing frontend:**
- Follow IMPLEMENTATION_PLAN.md Phase 4
- Use Nordic color palette from PRINCIPLES.md
- Slide-out panels for view/edit (not modals)
- Human-readable values (no IDs)

---

## Key Files to Review

1. **PRINCIPLES.md** - Architectural principles (MUST READ)
2. **IMPLEMENTATION_PLAN.md** - Complete 8-phase plan
3. **FEATURE_ANALYSIS.md** - All features from old app
4. **backend/services/ai_service.rb** - AI provider factory
5. **backend/lib/api_clients/venice_client.rb** - Primary chat provider
6. **backend/lib/api_clients/openai_client.rb** - TTS only

---

## Common Issues & Solutions

### Issue: API keys not found
**Solution:** Run `ruby script/utilities/migrate_api_keys.rb` to copy from old codebase

### Issue: Database connection fails
**Solution:** 
1. Ensure PostgreSQL is running
2. Create databases: `createdb chatgpt2_0_development`
3. Check `DATABASE_URL` in `.env`

### Issue: Services return placeholder data
**Solution:** Implement database models first (Phase 3 priority)

### Issue: Dependencies not installed
**Solution:** 
```bash
cd backend
bundle install
```

---

## Development Workflow

1. **Start Backend:**
   ```bash
   cd backend
   bundle install
   bundle exec rackup
   # Or with auto-reload:
   rerun 'rackup'
   ```

2. **Run Migrations:**
   ```bash
   cd backend
   # TBD: Migration command
   ```

3. **Test API:**
   ```bash
   curl http://localhost:4567/
   # Should return: {"status":"ok","message":"ChatGPT v2.0 API"}
   ```

4. **Run Tests:**
   ```bash
   cd backend
   # TBD: Test command
   ```

---

## Architecture Decisions Made

1. **Venice.ai is default** - All chat completions use Venice by default
2. **OpenAI for TTS only** - TTS always uses OpenAI, regardless of chat provider
3. **Lazy loading** - API keys loaded on demand (fail fast if not configured)
4. **No fallbacks** - Fail fast with clear error messages (per PRINCIPLES.md)
5. **Base classes** - All common patterns in base classes (DRY)
6. **Service objects** - Business logic in service classes
7. **Factory pattern** - AIService uses factory for provider selection

---

## Feature Parity Checklist

From FEATURE_ANALYSIS.md, here's what needs to be implemented:

### ✅ Implemented
- [x] Base classes (DRY pattern)
- [x] API clients (Venice, OpenAI)
- [x] Chat service structure
- [x] AI service with extended dialogue
- [x] TTS service with intelligent chunking
- [x] Prompt service with synopsis generation

### ❌ Not Yet Implemented
- [ ] Database models and migrations
- [ ] RESTful API endpoints
- [ ] Frontend React application
- [ ] Image generation service
- [ ] Markdown export
- [ ] Word counting in real-time
- [ ] Roleplay formatting
- [ ] Opening lines management (UI)
- [ ] Chat history UI
- [ ] Settings UI
- [ ] Audio player component
- [ ] Image gallery component

---

## Next Session Priorities

1. **IMMEDIATE:** Create database models and migrations
2. **HIGH:** Implement RESTful API endpoints
3. **HIGH:** Update services to use models (remove placeholders)
4. **MEDIUM:** Set up RSpec testing framework
5. **MEDIUM:** Create frontend structure (React + TypeScript)
6. **LOW:** Implement image generation service
7. **LOW:** Add markdown export functionality

---

## Quick Reference

### Project Root
`/Users/jimfreeman/Coding projects/chatGPTv2`

### Backend Location
`backend/`

### API Keys Location
`backend/.env` (not in git)

### Old Codebase Reference
`chatgpt1_0/` (not in git, for reference only)

### GitHub Repository
`https://github.com/jcf608/chatgpt2_0`

### Key Commands
```bash
# Migrate API keys
ruby script/utilities/migrate_api_keys.rb

# Start backend
cd backend && bundle exec rackup

# Install dependencies
cd backend && bundle install
```

---

## Questions to Resolve

1. **Database:** Which migration tool? (Sequel migrations or manual SQL?)
2. **Testing:** RSpec setup - need to configure test database
3. **Frontend:** When to start? (After API endpoints or in parallel?)
4. **Deployment:** Target platform? (Heroku, AWS, self-hosted?)

---

## Contact & Context

- **Project:** ChatGPT v2.0 - Sinatra + React overhaul
- **Old Codebase:** CLI-based Ruby application in `chatgpt1_0/`
- **Architecture:** Follows PRINCIPLES.md strictly
- **Status:** Phase 2 complete, ready for Phase 3

---

## Important Reminders

1. **Always read PRINCIPLES.md** before making architectural decisions
2. **Venice.ai is default** for chat, OpenAI is TTS only
3. **No fallbacks** - fail fast with clear errors
4. **DRY** - use base classes, don't duplicate code
5. **Test incrementally** - after each major component
6. **Never commit errors** - fix linter/test errors first
7. **Lazy loading** - API keys loaded on demand
8. **Keep files short** - 5-15 lines per method

---

**End of Handoff Document**

*Last Updated: November 18, 2024*
*Phase: 2 of 8 Complete*

