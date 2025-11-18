# ChatGPT v2.0 - Sinatra + React Implementation Plan

## Project Overview

Complete overhaul of the ChatGPT CLI application into a modern web application using:
- **Backend**: Sinatra (Ruby) - Lightweight, flexible web framework
- **Frontend**: React (TypeScript) - Modern, component-based UI
- **Database**: PostgreSQL - Robust data persistence
- **Architecture**: RESTful API with separation of concerns

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Phase 1: Foundation Setup](#phase-1-foundation-setup)
4. [Phase 2: Core Backend Services](#phase-2-core-backend-services)
5. [Phase 3: API Endpoints](#phase-3-api-endpoints)
6. [Phase 4: Frontend Foundation](#phase-4-frontend-foundation)
7. [Phase 5: Core Features](#phase-5-core-features)
8. [Phase 6: Advanced Features](#phase-6-advanced-features)
9. [Phase 7: Testing & Quality](#phase-7-testing--quality)
10. [Phase 8: Deployment](#phase-8-deployment)

---

## Architecture Overview

### Technology Stack

**Backend:**
- Sinatra 3.0+ (Ruby web framework)
- PostgreSQL (database)
- Sequel ORM (database abstraction)
- Rack (web server interface)
- Puma (application server)

**Frontend:**
- React 18+ (UI framework)
- TypeScript (type safety)
- Vite (build tool)
- React Router (routing)
- Axios (HTTP client)
- Tailwind CSS (styling - following PRINCIPLES.md color palette)

**Development:**
- RSpec (backend testing)
- Jest + React Testing Library (frontend testing)
- RuboCop (Ruby linting)
- ESLint + Prettier (TypeScript linting/formatting)

### Architecture Principles (from PRINCIPLES.md)

- ✅ **DRY**: Delegate to base classes, use metaprogramming for repetitive patterns
- ✅ **Single Responsibility**: Each class/file has one clear purpose
- ✅ **Keep files short**: 5-15 lines per method, delegate to superclasses
- ✅ **No hardcoding**: Discover data dynamically from configuration
- ✅ **Fail fast**: No fallbacks, clear error messages
- ✅ **Test at reasonable increments**: Test after each major component
- ✅ **Script organization**: All scripts in `script/` directory
- ✅ **Prefer Ruby scripts**: Over shell scripts for maintainability

---

## Project Structure

```
chatgpt2_0/
├── PRINCIPLES.md                    # Architectural principles
├── README.md                        # Project documentation
├── .gitignore
├── .ruby-version                    # Ruby 3.3.3
│
├── backend/                         # Sinatra application
│   ├── Gemfile
│   ├── config.ru                   # Rack configuration
│   ├── app.rb                      # Main Sinatra application
│   ├── config/
│   │   ├── database.yml            # Database configuration
│   │   └── environment.rb          # Environment setup
│   ├── models/                     # Sequel models
│   │   ├── base_model.rb          # Base class for all models
│   │   ├── chat.rb
│   │   ├── message.rb
│   │   ├── prompt.rb
│   │   └── audio_output.rb
│   ├── services/                   # Business logic
│   │   ├── base_service.rb         # Base service class
│   │   ├── chat_service.rb
│   │   ├── ai_service.rb          # OpenAI/Venice integration
│   │   ├── tts_service.rb         # Text-to-speech
│   │   └── prompt_service.rb
│   ├── api/                        # API endpoints
│   │   ├── base_api.rb            # Base API class
│   │   ├── chats_api.rb
│   │   ├── messages_api.rb
│   │   ├── prompts_api.rb
│   │   └── audio_api.rb
│   ├── lib/                        # Utilities
│   │   ├── api_clients/
│   │   │   ├── base_client.rb
│   │   │   ├── openai_client.rb
│   │   │   └── venice_client.rb
│   │   └── validators/
│   ├── db/
│   │   ├── migrations/            # Sequel migrations
│   │   └── seeds.rb               # Seed data
│   └── spec/                      # RSpec tests
│       ├── spec_helper.rb
│       ├── models/
│       ├── services/
│       └── api/
│
├── frontend/                       # React application
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.json
│   ├── index.html
│   ├── src/
│   │   ├── main.tsx               # Entry point
│   │   ├── App.tsx                # Root component
│   │   ├── api/                   # API client
│   │   │   ├── client.ts
│   │   │   └── endpoints.ts
│   │   ├── components/            # React components
│   │   │   ├── common/           # Reusable components
│   │   │   │   ├── Button.tsx
│   │   │   │   ├── Input.tsx
│   │   │   │   ├── Modal.tsx
│   │   │   │   └── SlideOut.tsx
│   │   │   ├── chat/             # Chat-specific
│   │   │   │   ├── ChatWindow.tsx
│   │   │   │   ├── MessageList.tsx
│   │   │   │   ├── MessageInput.tsx
│   │   │   │   └── ChatHistory.tsx
│   │   │   ├── prompts/          # Prompt management
│   │   │   │   ├── PromptSelector.tsx
│   │   │   │   └── PromptEditor.tsx
│   │   │   └── audio/            # Audio features
│   │   │       └── AudioPlayer.tsx
│   │   ├── pages/                # Page components
│   │   │   ├── Dashboard.tsx
│   │   │   ├── ChatPage.tsx
│   │   │   └── SettingsPage.tsx
│   │   ├── hooks/                # Custom React hooks
│   │   │   ├── useChat.ts
│   │   │   ├── useAudio.ts
│   │   │   └── usePrompts.ts
│   │   ├── store/                # State management (Zustand/Context)
│   │   │   ├── chatStore.ts
│   │   │   └── settingsStore.ts
│   │   ├── styles/               # Global styles
│   │   │   ├── index.css
│   │   │   └── theme.css         # Color palette from PRINCIPLES.md
│   │   └── utils/                # Utility functions
│   └── __tests__/                # Jest tests
│
├── script/                        # Development scripts
│   ├── README.md                  # Script documentation
│   ├── utilities/
│   │   ├── setup_db.rb           # Database setup
│   │   └── seed_data.rb          # Seed data generation
│   └── manual_tests/
│       └── test_api.rb           # Manual API testing
│
└── doc/                           # Documentation (per PRINCIPLES.md)
    ├── README.md                  # Documentation index
    ├── architecture/
    ├── guides/
    └── implementation/
```

---

## Phase 1: Foundation Setup

### 1.1 Backend Setup

**Tasks:**
- [ ] Initialize Sinatra application structure
- [ ] Set up Gemfile with dependencies:
  - `sinatra` (3.0+)
  - `sequel` (PostgreSQL adapter)
  - `pg` (PostgreSQL gem)
  - `rack-cors` (CORS handling)
  - `dotenv` (environment variables)
  - `rspec` (testing)
  - `rubocop` (linting)
- [ ] Configure `config.ru` for Rack
- [ ] Set up database configuration (`config/database.yml`)
- [ ] Create environment setup (`config/environment.rb`)
- [ ] Initialize Sequel database connection
- [ ] Set up `.env` file for API keys
- [ ] Create base API class with error handling

**Files to Create:**
```
backend/
├── Gemfile
├── config.ru
├── app.rb
├── config/
│   ├── database.yml
│   └── environment.rb
└── .env.example
```

**Key Implementation:**
- Base API class following DRY principles (error handling in base class)
- Environment-based configuration (development, test, production)
- Database connection pooling

### 1.2 Frontend Setup

**Tasks:**
- [ ] Initialize React + TypeScript project with Vite
- [ ] Configure TypeScript (`tsconfig.json`)
- [ ] Set up Tailwind CSS with PRINCIPLES.md color palette
- [ ] Configure Vite for development and production builds
- [ ] Set up ESLint and Prettier
- [ ] Create base API client with Axios
- [ ] Set up React Router
- [ ] Create theme configuration (colors from PRINCIPLES.md)

**Files to Create:**
```
frontend/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tailwind.config.js
├── src/
│   ├── main.tsx
│   ├── App.tsx
│   ├── api/
│   │   └── client.ts
│   └── styles/
│       ├── index.css
│       └── theme.css
```

**Color Palette (from PRINCIPLES.md):**
- Backgrounds: `#FAFAFA`, `#FFFFFF`, `#F5F5F7`, `#E5E5E5`
- Sidebar: `#2C2C2E`
- Primary: `#5E87B0`, `#8BA3B8`, `#6B9AC4`
- Text: `#1C1C1E`, `#3A3A3C`, `#636366`, `#8E8E93`
- Semantic: Success `#5A8F7B`, Warning `#D4A373`, Error `#B85C5C`

### 1.3 Database Schema

**Tasks:**
- [ ] Create Sequel migrations for:
  - `chats` table
  - `messages` table
  - `prompts` table
  - `audio_outputs` table
  - `system_prompts` table (for base prompts)
- [ ] Set up foreign key relationships
- [ ] Add indexes for performance
- [ ] Create seed data script

**Database Schema:**
```ruby
# chats table
- id (primary key)
- title (string)
- created_at (timestamp)
- updated_at (timestamp)
- system_prompt_id (foreign key)
- api_provider (string: 'openai' | 'venice')
- voice (string: for TTS)

# messages table
- id (primary key)
- chat_id (foreign key)
- role (string: 'user' | 'assistant' | 'system')
- content (text)
- created_at (timestamp)
- sequence_number (integer)

# prompts table
- id (primary key)
- name (string, unique)
- content (text)
- created_at (timestamp)
- updated_at (timestamp)

# system_prompts table
- id (primary key)
- name (string, unique)
- content (text)
- is_base (boolean)
- created_at (timestamp)
- updated_at (timestamp)

# audio_outputs table
- id (primary key)
- chat_id (foreign key)
- file_path (string)
- voice (string)
- created_at (timestamp)
```

---

## Phase 2: Core Backend Services

### 2.1 Base Classes (DRY Principle)

**Tasks:**
- [ ] Create `BaseModel` class with common methods:
  - Timestamps
  - Validation helpers
  - Error handling
- [ ] Create `BaseService` class with:
  - Common error handling
  - Validation patterns
  - Logging
- [ ] Create `BaseApiClient` class with:
  - HTTP request handling
  - Timeout configuration
  - Error parsing
  - Retry logic

**Implementation Pattern:**
```ruby
# backend/models/base_model.rb
class BaseModel < Sequel::Model
  # Common validations, timestamps, etc.
end

# backend/services/base_service.rb
class BaseService
  def self.call(*args)
    new(*args).call
  end

  protected

  def handle_error(error)
    # Centralized error handling
  end
end
```

### 2.2 API Client Services

**Tasks:**
- [ ] Refactor `OpenAIClient` from v1.0:
  - Extend `BaseApiClient`
  - Implement chat completion
  - Implement text-to-speech
  - Handle rate limiting
- [ ] Refactor `VeniceClient` from v1.0:
  - Extend `BaseApiClient`
  - Implement chat completion
  - Share common patterns with OpenAI client
- [ ] Use metaprogramming to eliminate duplication (per PRINCIPLES.md)

**Key Features:**
- Lazy loading of API keys (fail fast if not configured)
- Proper error messages
- Request/response logging
- Timeout handling

### 2.3 Core Services

**Tasks:**
- [ ] `ChatService`:
  - Create new chat
  - Add message to chat
  - Get chat history
  - Clear conversation
  - Save chat
- [ ] `AIService`:
  - Factory pattern for provider selection
  - Send message to AI
  - Handle streaming responses (future)
- [ ] `TTSService`:
  - Generate audio from text
  - Chunk text intelligently
  - Combine audio segments
  - Save audio files
- [ ] `PromptService`:
  - Load base system prompts
  - Load user prompts
  - Combine prompts
  - Manage prompt library

**Service Pattern:**
```ruby
# backend/services/chat_service.rb
class ChatService < BaseService
  def initialize(chat_id = nil)
    @chat_id = chat_id
  end

  def create(title: nil)
    # Create new chat
  end

  def add_message(role:, content:)
    # Add message to chat
  end

  def get_messages
    # Retrieve all messages
  end
end
```

---

## Phase 3: API Endpoints

### 3.1 RESTful API Design

**Endpoints:**

```
GET    /api/v1/chats              # List all chats
POST   /api/v1/chats              # Create new chat
GET    /api/v1/chats/:id          # Get chat details
DELETE /api/v1/chats/:id          # Delete chat

GET    /api/v1/chats/:id/messages # Get chat messages
POST   /api/v1/chats/:id/messages # Add message to chat

POST   /api/v1/chats/:id/send     # Send message to AI (creates user + assistant messages)

GET    /api/v1/prompts            # List all prompts
POST   /api/v1/prompts            # Create prompt
GET    /api/v1/prompts/:id        # Get prompt
PUT    /api/v1/prompts/:id        # Update prompt
DELETE /api/v1/prompts/:id        # Delete prompt

POST   /api/v1/chats/:id/audio    # Generate audio from chat
GET    /api/v1/audio/:id          # Get audio file
```

### 3.2 API Implementation

**Tasks:**
- [ ] Create `BaseApi` class with:
  - JSON response formatting
  - Error handling middleware
  - Authentication (future)
  - Request validation
- [ ] Implement `ChatsApi`:
  - CRUD operations
  - Message management
  - Send message endpoint (integrates AI service)
- [ ] Implement `PromptsApi`:
  - CRUD operations
  - Prompt selection
- [ ] Implement `AudioApi`:
  - Audio generation
  - File serving
- [ ] Add CORS configuration
- [ ] Add request logging

**Error Response Format:**
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

**Success Response Format:**
```json
{
  "success": true,
  "data": {},
  "timestamp": "2024-01-01T00:00:00Z"
}
```

---

## Phase 4: Frontend Foundation

### 4.1 Base Components

**Tasks:**
- [ ] Create common components:
  - `Button` - Reusable button with variants
  - `Input` - Text input with validation
  - `Modal` - Modal dialog (for confirmations/errors)
  - `SlideOut` - Slide-out panel (per PRINCIPLES.md UI patterns)
  - `LoadingSpinner` - Loading states
  - `ErrorMessage` - Error display with copy-to-clipboard
- [ ] Implement theme system:
  - Color palette from PRINCIPLES.md
  - Typography scale
  - Spacing system
  - Animation utilities (ease-in-out)
- [ ] Create layout components:
  - `AppLayout` - Main app structure
  - `Sidebar` - Navigation sidebar
  - `Header` - Top header bar

**Component Pattern:**
```tsx
// frontend/src/components/common/Button.tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger';
  onClick: () => void;
  children: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({ variant = 'primary', ... }) => {
  // Implementation
};
```

### 4.2 State Management

**Tasks:**
- [ ] Set up Zustand (or Context API) for:
  - Chat state management
  - Settings state (API provider, voice, TTS enabled)
  - UI state (modals, slide-outs)
- [ ] Create stores:
  - `chatStore` - Current chat, messages, conversation
  - `settingsStore` - User preferences
  - `promptStore` - Available prompts

**Store Pattern:**
```typescript
// frontend/src/store/chatStore.ts
interface ChatState {
  currentChat: Chat | null;
  messages: Message[];
  isLoading: boolean;
  sendMessage: (content: string) => Promise<void>;
  clearChat: () => void;
}
```

### 4.3 API Integration

**Tasks:**
- [ ] Create API client with Axios:
  - Base URL configuration
  - Request/response interceptors
  - Error handling
  - TypeScript types for all endpoints
- [ ] Create custom hooks:
  - `useChat` - Chat operations
  - `useMessages` - Message operations
  - `usePrompts` - Prompt management
  - `useAudio` - Audio generation/playback

**API Client Pattern:**
```typescript
// frontend/src/api/client.ts
class ApiClient {
  private client: AxiosInstance;

  async getChats(): Promise<Chat[]> { }
  async createChat(data: CreateChatData): Promise<Chat> { }
  async sendMessage(chatId: string, content: string): Promise<Message> { }
}
```

---

## Phase 5: Core Features

### 5.1 Chat Interface

**Tasks:**
- [ ] Create `ChatWindow` component:
  - Message list with user/assistant distinction
  - Message input with send button
  - Real-time message updates
  - Loading states during AI responses
- [ ] Create `MessageList` component:
  - Display messages in chronological order
  - User messages on right, assistant on left
  - Timestamp display
  - Copy message functionality
- [ ] Create `MessageInput` component:
  - Text area with auto-resize
  - Send button (Enter to send, Shift+Enter for new line)
  - Character count (optional)
- [ ] Implement chat history:
  - List of previous chats
  - Search/filter chats
  - Delete chats
  - Load previous chat

**UI Requirements (from PRINCIPLES.md):**
- Slide-out panels for view/edit operations
- Modals only for loading states, errors, confirmations
- Human-readable values (no IDs in UI)
- Nordic color palette

### 5.2 Prompt Management

**Tasks:**
- [ ] Create `PromptSelector` component:
  - List of available prompts
  - Search/filter prompts
  - Select prompt to add to chat
  - Show prompt preview
- [ ] Create `PromptEditor` component:
  - Create new prompts
  - Edit existing prompts
  - Delete prompts
  - Preview prompt content
- [ ] Integrate prompt selection with chat:
  - Add selected prompt to system message
  - Show active prompt in chat header
  - Allow changing prompt mid-conversation

### 5.3 Settings

**Tasks:**
- [ ] Create `SettingsPage` component:
  - API provider selection (OpenAI/Venice)
  - Voice selection for TTS
  - TTS enable/disable toggle
  - System prompt configuration
- [ ] Persist settings:
  - Save to backend (future: user accounts)
  - Local storage for now
- [ ] Apply settings to chat:
  - Use selected API provider
  - Use selected voice for audio generation

---

## Phase 6: Advanced Features

### 6.1 Text-to-Speech

**Tasks:**
- [ ] Create `AudioPlayer` component:
  - Play/pause controls
  - Progress bar
  - Volume control
  - Download audio file
- [ ] Implement audio generation:
  - Generate audio from chat messages
  - Show progress during generation
  - Handle long conversations (chunking)
  - Save audio files
- [ ] Audio management:
  - List generated audio files
  - Delete old audio files
  - Play audio in browser

### 6.2 Chat Export

**Tasks:**
- [ ] Export chat to text file:
  - Format: User/Assistant messages
  - Include system prompt info
  - Include timestamps
  - Download as .txt file
- [ ] Export chat to markdown:
  - Formatted markdown
  - Code blocks preserved
  - Download as .md file

### 6.3 Enhanced Features

**Tasks:**
- [ ] Chat search:
  - Search within current chat
  - Search across all chats
  - Highlight search results
- [ ] Message actions:
  - Edit user messages (regenerate response)
  - Delete messages
  - Copy message content
- [ ] Conversation management:
  - Clear conversation
  - Start new chat
  - Duplicate chat

---

## Phase 7: Testing & Quality

### 7.1 Backend Testing

**Tasks:**
- [ ] Set up RSpec:
  - Test database configuration
  - Factory methods for test data
  - Shared examples for common patterns
- [ ] Model tests:
  - Validations
  - Associations
  - Methods
- [ ] Service tests:
  - Business logic
  - Error handling
  - Edge cases
- [ ] API tests:
  - Endpoint responses
  - Error cases
  - Authentication (future)
- [ ] Integration tests:
  - Full chat flow
  - AI service integration (mocked)
  - TTS service integration

**Testing Principles (from PRINCIPLES.md):**
- Test at reasonable increments (after each component)
- 80% code coverage minimum
- Save test results to files
- Never commit with known errors

### 7.2 Frontend Testing

**Tasks:**
- [ ] Set up Jest + React Testing Library:
  - Component rendering tests
  - User interaction tests
  - Hook tests
- [ ] Component tests:
  - Render correctly
  - Handle user interactions
  - Display errors properly
- [ ] Integration tests:
  - Full user flows
  - API integration (mocked)
- [ ] E2E tests (optional):
  - Critical user paths
  - Cross-browser testing

### 7.3 Code Quality

**Tasks:**
- [ ] Set up RuboCop:
  - Configure rules
  - Auto-fix on save
  - CI integration
- [ ] Set up ESLint + Prettier:
  - TypeScript rules
  - React rules
  - Auto-format on save
- [ ] Pre-commit hooks:
  - Run linters
  - Run tests
  - Prevent commits with errors

---

## Phase 8: Deployment

### 8.1 Production Setup

**Tasks:**
- [ ] Environment configuration:
  - Production database
  - API keys management
  - Environment variables
- [ ] Build configuration:
  - Frontend production build
  - Backend asset compilation
  - Optimize for production
- [ ] Server setup:
  - Puma configuration
  - Nginx reverse proxy (optional)
  - SSL certificates
- [ ] Database setup:
  - Production migrations
  - Backup strategy
  - Performance tuning

### 8.2 CI/CD

**Tasks:**
- [ ] GitHub Actions workflow:
  - Run tests on PR
  - Lint code
  - Build application
  - Deploy on merge to main
- [ ] Deployment pipeline:
  - Test environment
  - Staging environment
  - Production environment

---

## Implementation Guidelines

### Code Organization

1. **Keep files short**: Methods should be 5-15 lines
2. **Delegate to base classes**: Common patterns in base classes
3. **Use metaprogramming**: Eliminate repetitive case statements
4. **Single responsibility**: One purpose per class/file
5. **No hardcoding**: Discover from configuration/database

### Error Handling

1. **Fail fast**: No fallbacks, clear error messages
2. **User-friendly errors**: Primary message + remediation steps
3. **Technical details**: In slide-out panel with copy-to-clipboard
4. **Logging**: Separate error log, include full context

### UI/UX

1. **Slide-out panels**: For view/edit operations
2. **Modals**: Only for loading, errors, confirmations
3. **Human-readable**: No IDs, use names/labels
4. **Color palette**: Follow PRINCIPLES.md Nordic theme
5. **Animations**: Ease-in-out timing, 300ms duration

### Testing

1. **Test incrementally**: After each major component
2. **Save results**: Always save test output to files
3. **Never commit errors**: Fix linter/test errors before commit
4. **80% coverage**: Minimum target

---

## Migration from v1.0

### Data Migration

**Tasks:**
- [ ] Create migration script:
  - Import chat files from `chats/` directory
  - Import prompts from `prompts/` directory
  - Import audio files metadata
  - Preserve timestamps
- [ ] Validate migrated data:
  - Check all chats imported
  - Verify message order
  - Confirm prompts loaded

### Feature Parity

**Checklist:**
- [x] Chat with AI (OpenAI/Venice)
- [x] System prompts (base + user prompts)
- [x] Text-to-speech
- [x] Audio generation from chats
- [x] Chat history saving
- [x] Prompt management
- [x] Voice selection
- [x] API provider selection

---

## Timeline Estimate

- **Phase 1**: 2-3 days (Foundation)
- **Phase 2**: 3-4 days (Backend Services)
- **Phase 3**: 2-3 days (API Endpoints)
- **Phase 4**: 3-4 days (Frontend Foundation)
- **Phase 5**: 5-7 days (Core Features)
- **Phase 6**: 3-4 days (Advanced Features)
- **Phase 7**: 4-5 days (Testing)
- **Phase 8**: 2-3 days (Deployment)

**Total**: ~24-33 days (approximately 5-6 weeks)

---

## Next Steps

1. Review and approve this plan
2. Set up development environment
3. Begin Phase 1: Foundation Setup
4. Create GitHub issues for each phase
5. Start implementation following PRINCIPLES.md guidelines

---

## Notes

- This plan follows all principles from PRINCIPLES.md
- Breaking changes are acceptable (greenfield project)
- Focus on clean architecture over backward compatibility
- Test incrementally, never commit with errors
- Use DRY principles throughout
- Prefer Ruby scripts over shell scripts
- Organize all scripts in `script/` directory

