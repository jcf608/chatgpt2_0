# ChatGPT v2.0 - Project Handoff Document

**Date:** December 19, 2024  
**Status:** Phase 3 Complete - API Endpoints Implemented  
**Next Phase:** Phase 4 - Frontend Foundation (or Phase 7 - Testing)

---

## Project Overview

Complete overhaul of ChatGPT CLI application into a modern web application:
- **Backend:** Sinatra (Ruby) + File-based storage ✅
- **Frontend:** React + TypeScript + Vite (Phase 4 - TODO)
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
│   ├── app.rb                     # Main Sinatra application (API mounted)
│   ├── config/
│   │   └── environment.rb         # Environment setup
│   ├── models/                    # File-based models ✅
│   │   ├── base_model.rb          # Base class for all models
│   │   ├── chat.rb                # Chat model (JSON with embedded messages)
│   │   ├── prompt.rb              # Prompt model (.prompt file format)
│   │   ├── audio_output.rb        # Audio metadata model
│   │   └── image.rb               # Image metadata model
│   ├── services/                  # Business logic ✅
│   │   ├── base_service.rb        # Base class for services
│   │   ├── chat_service.rb        # Chat management (uses Chat model)
│   │   ├── ai_service.rb          # AI provider factory
│   │   ├── tts_service.rb         # Text-to-speech (OpenAI)
│   │   └── prompt_service.rb      # Prompt management
│   ├── api/                       # API endpoints ✅
│   │   ├── base_api.rb            # Base API class (error handling, JSON responses)
│   │   ├── chats_api.rb           # Chat endpoints
│   │   ├── messages_api.rb        # Message endpoints
│   │   ├── prompts_api.rb         # Prompt endpoints
│   │   └── audio_api.rb           # Audio endpoints
│   ├── lib/
│   │   └── api_clients/
│   │       ├── base_client.rb     # Base API client
│   │       ├── venice_client.rb   # Venice.ai client
│   │       └── openai_client.rb   # OpenAI client (TTS only)
│   ├── data/                      # File storage directory ✅
│   │   ├── chats/                 # Chat JSON files
│   │   ├── prompts/               # Prompt .prompt files
│   │   ├── audio/                 # Audio files (.mp3)
│   │   └── images/                # Image files (.png)
│   └── spec/                      # RSpec tests (Phase 7 - TODO)
│
├── frontend/                       # React application (Phase 4 - TODO)
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
- [x] Set up file storage structure
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
- `backend/.env` - API keys (OpenAI, Venice) - **NOT in git**

### Phase 2: Core Backend Services ✅

**Completed:**
- [x] Created `BaseModel` class (file-based model base)
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

### Phase 3: API Endpoints ✅

**Completed:**
- [x] Created file storage directories (`data/chats/`, `data/prompts/`, `data/audio/`, `data/images/`)
- [x] Created `Chat` model (JSON file storage with embedded messages)
- [x] Created `Prompt` model (file-based, `.prompt` format)
- [x] Created `AudioOutput` model (metadata in JSON, files in `data/audio/`)
- [x] Created `Image` model (metadata in JSON, files in `data/images/`)
- [x] Created `BaseAPI` class (JSON response formatting, error handling, request validation)
- [x] Updated `ChatService` to use Chat model (removed placeholders)
- [x] Implemented `ChatsAPI` endpoints
- [x] Implemented `MessagesAPI` endpoints
- [x] Implemented `PromptsAPI` endpoints
- [x] Implemented `AudioAPI` endpoints
- [x] Mounted all API endpoints in `app.rb`

**Key Files:**
- `backend/models/chat.rb` - Chat model with embedded messages
- `backend/models/prompt.rb` - Prompt model (.prompt files)
- `backend/models/audio_output.rb` - Audio metadata model
- `backend/models/image.rb` - Image metadata model
- `backend/api/base_api.rb` - Base API class with error handling
- `backend/api/chats_api.rb` - Chat REST endpoints
- `backend/api/messages_api.rb` - Message REST endpoints
- `backend/api/prompts_api.rb` - Prompt REST endpoints
- `backend/api/audio_api.rb` - Audio REST endpoints

**API Endpoints Implemented:**

**Chats API:**
```
GET    /api/v1/chats              # List all chats
POST   /api/v1/chats              # Create new chat
GET    /api/v1/chats/:id          # Get chat details
DELETE /api/v1/chats/:id          # Delete chat
POST   /api/v1/chats/:id/send     # Send message to AI
POST   /api/v1/chats/:id/extend   # Extended dialogue generation
POST   /api/v1/chats/:id/continue # Continue conversation
GET    /api/v1/chats/:id/word-count # Get word count
POST   /api/v1/chats/:id/synopsis # Generate prompt synopsis
POST   /api/v1/chats/:id/opening  # Start chat with opening line
```

**Messages API:**
```
GET    /api/v1/chats/:id/messages # Get chat messages
POST   /api/v1/chats/:id/messages # Add message to chat
```

**Prompts API:**
```
GET    /api/v1/prompts            # List all prompts
POST   /api/v1/prompts            # Create prompt
GET    /api/v1/prompts/:id        # Get prompt
PUT    /api/v1/prompts/:id        # Update prompt
DELETE /api/v1/prompts/:id        # Delete prompt
GET    /api/v1/opening-lines      # List opening lines for prompt
```

**Audio API:**
```
POST   /api/v1/chats/:id/audio    # Generate audio from chat
GET    /api/v1/audio/:id          # Get audio metadata
GET    /api/v1/audio/:id/file     # Get audio file
```

---

## Next Steps: Phase 4 or Phase 7

### Option 1: Phase 4 - Frontend Foundation

**Priority Tasks:**
1. **Set Up React + TypeScript + Vite:**
   - Initialize React project with Vite
   - Configure TypeScript
   - Set up Tailwind CSS with PRINCIPLES.md color palette
   - Configure ESLint and Prettier
   - Set up React Router

2. **Create Base Components:**
   - `Button`, `Input`, `Modal`, `SlideOut` (per PRINCIPLES.md UI patterns)
   - `LoadingSpinner`, `ErrorMessage`
   - Layout components (`AppLayout`, `Sidebar`, `Header`)

3. **Set Up State Management:**
   - Zustand or Context API
   - `chatStore`, `settingsStore`, `promptStore`

4. **Create API Client:**
   - Axios-based API client
   - TypeScript types for all endpoints
   - Error handling

5. **Create Custom Hooks:**
   - `useChat`, `useMessages`, `usePrompts`, `useAudio`

### Option 2: Phase 7 - Testing & Quality

**Priority Tasks:**
1. **Set Up RSpec:**
   - Configure RSpec for Sinatra
   - Test file storage configuration
   - Factory methods for test data

2. **Write Tests:**
   - Model tests (Chat, Prompt, AudioOutput, Image)
   - Service tests (ChatService, AIService, TTSService, PromptService)
   - API endpoint tests (all endpoints)

3. **Set Up Code Quality:**
   - RuboCop configuration
   - Pre-commit hooks
   - Test coverage reporting

---

## Important Implementation Notes

### API Key Management

- **Location:** `backend/.env` (NOT in git)
- **Migration:** Run `ruby script/utilities/migrate_api_keys.rb` to copy from old codebase
- **Environment Variables:**
  - `OPENAI_API_KEY` - For TTS (required)
  - `VENICE_API_KEY` - For chat (required)
  - `RACK_ENV` - Environment (development/test/production)
  - `PORT` - Server port (default: 4567)

### File Storage Structure

**Directories Created:**
- `backend/data/chats/` - Chat JSON files
- `backend/data/prompts/` - Prompt .prompt files
- `backend/data/audio/` - Audio .mp3 files
- `backend/data/images/` - Image .png files

**File Naming Conventions:**
- Chats: `{uuid}.json` (UUID generated on creation)
- Prompts: `{name}.prompt`
- Audio: Stored as `{uuid}.mp3` with metadata in `{uuid}.json`
- Images: Stored as `{uuid}.png` with metadata in `{uuid}.json`

**Chat JSON Format:**
```json
{
  "id": "uuid",
  "title": "Chat title",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z",
  "system_prompt_id": "prompt-name",
  "api_provider": "venice",
  "voice": "echo",
  "messages": [
    {
      "id": "msg-id",
      "role": "user",
      "content": "Message content",
      "sequence_number": 1,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "metadata": {
    "word_count": 1000,
    "message_count": 5
  }
}
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

### API Response Format

**Success Response:**
```json
{
  "success": true,
  "data": { ... },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": {
    "message": "Clear error message",
    "code": "ERROR_CODE",
    "details": {}
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
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
- Test file storage configuration needed
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
- Tailwind CSS setup needed (use PRINCIPLES.md color palette)
- Component structure needed
- API client setup needed

**When implementing frontend:**
- Follow IMPLEMENTATION_PLAN.md Phase 4
- Use Nordic color palette from PRINCIPLES.md
- Slide-out panels for view/edit (not modals)
- Human-readable values (no IDs)

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

2. **Test API:**
   ```bash
   curl http://localhost:4567/
   # Should return: {"status":"ok","message":"ChatGPT v2.0 API"}
   
   # Create a chat
   curl -X POST http://localhost:4567/api/v1/chats \
     -H "Content-Type: application/json" \
     -d '{"api_provider": "venice", "title": "Test Chat"}'
   ```

3. **Run Tests (when implemented):**
   ```bash
   cd backend
   # TBD: Test command
   ```

---

## Common Issues & Solutions

### Issue: API keys not found
**Solution:** Run `ruby script/utilities/migrate_api_keys.rb` to copy from old codebase

### Issue: File storage directories missing
**Solution:** 
- Directories are already created, but if needed:
  ```bash
  cd backend
  mkdir -p data/chats data/prompts data/audio data/images
  ```
- Check file permissions

### Issue: Services returning placeholder data
**Solution:** ✅ Fixed! Services now use file-based models

### Issue: Dependencies not installed
**Solution:** 
```bash
cd backend
bundle install
```

### Issue: Model JSON parsing errors
**Solution:** 
- Check that JSON files are valid
- Ensure timestamps are in ISO8601 format
- Messages should have symbol keys after loading

---

## Architecture Decisions Made

1. **Venice.ai is default** - All chat completions use Venice by default
2. **OpenAI for TTS only** - TTS always uses OpenAI, regardless of chat provider
3. **Lazy loading** - API keys loaded on demand (fail fast if not configured)
4. **No fallbacks** - Fail fast with clear error messages (per PRINCIPLES.md)
5. **Base classes** - All common patterns in base classes (DRY)
6. **Service objects** - Business logic in service classes
7. **Factory pattern** - AIService uses factory for provider selection
8. **Embedded messages** - Messages stored in Chat JSON (not separate files)
9. **File-based storage** - No database, simple JSON/file storage
10. **ISO8601 timestamps** - All timestamps in ISO8601 format for consistency

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
- [x] File-based models (Chat, Prompt, AudioOutput, Image)
- [x] RESTful API endpoints
- [x] Chat management (CRUD)
- [x] Message management
- [x] Prompt management (CRUD)
- [x] Audio generation endpoints
- [x] Extended dialogue generation
- [x] Continue conversation
- [x] Word count tracking

### ❌ Not Yet Implemented
- [ ] Frontend React application
- [ ] Image generation service
- [ ] Markdown export
- [ ] Word counting in real-time (UI)
- [ ] Roleplay formatting (UI)
- [ ] Opening lines management (UI)
- [ ] Chat history UI
- [ ] Settings UI
- [ ] Audio player component
- [ ] Image gallery component
- [ ] Tests (RSpec)

---

## Next Session Priorities

**Choose one of these paths:**

### Path 1: Frontend Development (Phase 4)
1. **IMMEDIATE:** Set up React + TypeScript + Vite
2. **HIGH:** Create base components and API client
3. **HIGH:** Implement chat interface
4. **MEDIUM:** Implement prompt management UI
5. **MEDIUM:** Implement audio player component

### Path 2: Testing (Phase 7)
1. **IMMEDIATE:** Set up RSpec
2. **HIGH:** Write model tests
3. **HIGH:** Write service tests
4. **HIGH:** Write API endpoint tests
5. **MEDIUM:** Set up code quality tools (RuboCop, coverage)

### Path 3: Advanced Features (Phase 6)
1. **IMMEDIATE:** Implement image generation service
2. **HIGH:** Add markdown export functionality
3. **MEDIUM:** Enhance extended dialogue features

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

# Test health endpoint
curl http://localhost:4567/
```

### API Base URL
`http://localhost:4567`

### API Version
`/api/v1/`

---

## Questions to Resolve

1. **Frontend:** When to start? (After API endpoints or in parallel?)
2. **Testing:** Start with frontend or backend tests first?
3. **Deployment:** Target platform? (Heroku, AWS, self-hosted?)
4. **Image Generation:** Which service? (OpenAI DALL-E, Stable Diffusion?)

---

## Contact & Context

- **Project:** ChatGPT v2.0 - Sinatra + React overhaul
- **Old Codebase:** CLI-based Ruby application in `chatgpt1_0/`
- **Architecture:** Follows PRINCIPLES.md strictly
- **Status:** Phase 3 complete (API Endpoints), ready for Phase 4 (Frontend) or Phase 7 (Testing)

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
9. **File-based storage** - Messages embedded in Chat JSON
10. **ISO8601 timestamps** - All timestamps in ISO8601 format

---

## Recent Changes Summary

### Phase 3 Completion (December 19, 2024)

**Models Created:**
- `Chat` - JSON storage with embedded messages
- `Prompt` - .prompt file format
- `AudioOutput` - Audio metadata with file references
- `Image` - Image metadata with file references

**API Endpoints Created:**
- `ChatsAPI` - Full CRUD + chat actions (send, extend, continue, synopsis, opening)
- `MessagesAPI` - Get and add messages
- `PromptsAPI` - Full CRUD + opening lines
- `AudioAPI` - Generate audio, get metadata, serve files

**Services Updated:**
- `ChatService` - Now uses Chat model (removed all placeholders)

**Key Files:**
- `backend/api/base_api.rb` - Base API with error handling
- `backend/models/*.rb` - All file-based models
- `backend/app.rb` - All endpoints mounted

**Storage:**
- All data directories created
- File naming conventions established
- JSON format standardized with ISO8601 timestamps

---

**End of Handoff Document**

*Last Updated: December 19, 2024*
*Phase: 3 of 8 Complete*
*Next: Phase 4 (Frontend) or Phase 7 (Testing)*
