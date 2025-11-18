# ChatGPT v2.0 - Sinatra + React Implementation Plan

## Project Overview

Complete overhaul of the ChatGPT CLI application into a modern web application using:
- **Backend**: Sinatra (Ruby) - Lightweight, flexible web framework
- **Frontend**: React (TypeScript) - Modern, component-based UI
- **Storage**: File-based storage - Simple, no database required
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

### Provider Architecture

**Critical Understanding:**
- **Venice.ai**: Primary/default provider for chat completions
  - System prompts are sent to Venice.ai
  - Chat conversations use Venice.ai by default
  - Users can optionally switch to OpenAI for chat
  
- **OpenAI**: Used exclusively for text-to-speech
  - TTS always uses OpenAI API, regardless of chat provider
  - Voice selection applies to OpenAI TTS
  - Chat provider selection does NOT affect TTS provider

**Key Points:**
- System prompts → Venice.ai (or selected chat provider)
- Chat completions → Venice.ai (default) or OpenAI (optional)
- Text-to-speech → OpenAI (always)

### Technology Stack

**Backend:**
- Sinatra 3.0+ (Ruby web framework)
- File-based storage (JSON/YAML files)
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
│   │   └── environment.rb          # Environment setup
│   ├── models/                     # File-based models
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
│   ├── data/                      # File storage directory
│   │   ├── chats/                # Chat files
│   │   ├── prompts/              # Prompt files
│   │   └── audio/                # Audio files
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
│   │   └── setup_data.rb         # File storage setup
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
  - `rack-cors` (CORS handling)
  - `dotenv` (environment variables)
  - `rspec` (testing)
  - `rubocop` (linting)
- [ ] Configure `config.ru` for Rack
- [ ] Create environment setup (`config/environment.rb`)
- [ ] Set up `.env` file for API keys
- [ ] Create base API class with error handling
- [ ] Set up file storage directories (`data/chats`, `data/prompts`, `data/audio`)

**Files to Create:**
```
backend/
├── Gemfile
├── config.ru
├── app.rb
├── config/
│   └── environment.rb
├── data/
│   ├── chats/
│   ├── prompts/
│   └── audio/
└── .env.example
```

**Key Implementation:**
- Base API class following DRY principles (error handling in base class)
- Environment-based configuration (development, test, production)
- File-based storage with JSON/YAML format

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

### 1.3 File Storage Structure

**Tasks:**
- [ ] Create file storage directories:
  - `data/chats/` - Chat conversation files (JSON format)
  - `data/prompts/` - User prompt files (`.prompt` format)
  - `data/audio/` - Generated audio files (`.mp3` format)
  - `data/images/` - Generated image files (`.png` format)
- [ ] Define file naming conventions:
  - Chats: `YYYYMMDD_HHMMSS_dialogue_[N]words.json`
  - Prompts: `[name].prompt`
  - Audio: `YYYYMMDD_HHMMSS_[description].mp3`
- [ ] Create file storage service classes

**File Storage Format:**
```json
// data/chats/YYYYMMDD_HHMMSS_dialogue_[N]words.json
{
  "id": "unique-id",
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
      "created_at": "2024-01-01T00:00:00Z",
      "sequence_number": 1
    }
  ],
  "metadata": {
    "word_count": 1000,
    "audio_file": "path/to/audio.mp3"
  }
}
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
class BaseModel
  # Common file operations, validations, etc.
  def self.load(id)
    # Load from file
  end
  
  def save
    # Save to file
  end
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
- [ ] Refactor `VeniceClient` from v1.0:
  - Extend `BaseApiClient`
  - Implement chat completion (primary/default provider)
  - System prompts sent to Venice.ai
  - Handle rate limiting
- [ ] Refactor `OpenAIClient` from v1.0:
  - Extend `BaseApiClient`
  - Implement text-to-speech ONLY (not chat completion)
  - TTS is always via OpenAI, regardless of chat provider
  - Handle rate limiting
- [ ] Use metaprogramming to eliminate duplication (per PRINCIPLES.md)

**Key Architecture Points:**
- **Venice.ai**: Default provider for chat completions and system prompts
- **OpenAI**: Used exclusively for text-to-speech (separate from chat provider)
- **Provider Selection**: Users can switch chat provider (Venice/OpenAI), but TTS always uses OpenAI
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
  - Factory pattern for provider selection (Venice default, OpenAI optional)
  - Send message to AI (system prompts go to selected provider)
  - Default to Venice.ai for chat completions
  - **Venice-specific parameters**:
    - `include_venice_system_prompt: false`
    - `top_p: 0.9`
    - `repetition_penalty: 1.1`
  - Handle streaming responses (future)
  - **Extended dialogue generation**:
    - Multi-segment generation
    - Word count tracking
    - Progress callbacks
    - Interrupt handling
  - **Continue conversation**:
    - Context-aware continuation
    - Smart prompt generation
    - Word count management
- [ ] `TTSService`:
  - **Always uses OpenAI** (regardless of chat provider)
  - Generate audio from text
  - Chunk text intelligently
  - Combine audio segments
  - Save audio files
- [ ] `PromptService`:
  - Load base system prompts (`system_prompts.txt`)
  - Load user prompts (`.prompt` files)
  - Load opening lines (`.opening_lines` files)
  - Combine prompts (base + user)
  - Manage prompt library
  - **Prompt synopsis generation** (using Venice.ai):
    - Analyze conversation
    - Extract system prompts/instructions
    - Extract character roles/personalities
    - Extract themes and scenarios
    - Extract writing style/format
    - Generate concise synopsis (< 500 words)
  - Prompt search and filtering
  - Prompt preview/truncation

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

POST   /api/v1/chats/:id/extend   # Extended dialogue generation (target word count)
POST   /api/v1/chats/:id/continue # Continue conversation (add words)
POST   /api/v1/chats/:id/images   # Generate images from chat
GET    /api/v1/chats/:id/word-count # Get word count

GET    /api/v1/opening-lines      # List opening lines files
POST   /api/v1/chats/:id/opening  # Start chat with opening line

POST   /api/v1/chats/:id/synopsis # Generate prompt synopsis
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
  - Real-time message updates (streaming responses - future enhancement)
  - Loading states during AI responses
  - Word count display (real-time)
  - Progress indicators for extended generation
- [ ] Create `MessageList` component:
  - Display messages in chronological order
  - User messages on right, assistant on left
  - Timestamp display
  - Copy message functionality
  - **Roleplay formatting**: Special display for character names (DADDY:, BARRY:, SAMMY:)
  - Character emoji indicators
  - Markdown rendering (code blocks, formatting)
- [ ] Create `MessageInput` component:
  - Text area with auto-resize
  - Send button (Enter to send, Shift+Enter for new line)
  - Character count
  - Word count preview
  - Command recognition (`auto`, `extend`, `clear`, etc.)
- [ ] Implement chat history:
  - List of previous chats
  - Search/filter chats
  - Delete chats
  - Load previous chat
  - Chat preview (first message, word count, date)
  - Sort by date, word count, name

**UI Requirements (from PRINCIPLES.md):**
- Slide-out panels for view/edit operations
- Modals only for loading states, errors, confirmations
- Human-readable values (no IDs in UI)
- Nordic color palette

### 5.2 Prompt Management

**Tasks:**
- [ ] Create `PromptSelector` component:
  - List of available prompts with preview
  - Search/filter prompts (by name, content)
  - Browse full prompt content (modal/slide-out)
  - Select prompt to add to chat
  - Show prompt preview (truncated, cleaned)
  - Partial name matching
  - Prompt categories/tags (enhancement)
- [ ] Create `PromptEditor` component:
  - Create new prompts
  - Edit existing prompts
  - Delete prompts
  - Preview prompt content
  - Prompt versioning (enhancement)
  - Prompt templates (enhancement)
- [ ] **Opening Lines Management**:
  - Create `OpeningLinesSelector` component
  - Load `.opening_lines` files
  - Random selection functionality
  - Auto-send to start conversation
  - Preview opening lines
  - Edit opening lines files
- [ ] Integrate prompt selection with chat:
  - Add selected prompt to system message
  - Combine base system prompt + user prompt
  - Show active prompt in chat header
  - Allow changing prompt mid-conversation
  - Preserve API provider when loading prompts

### 5.3 Settings

**Tasks:**
- [ ] Create `SettingsPage` component:
  - Chat API provider selection (Venice default, OpenAI optional)
  - Voice selection for TTS (always uses OpenAI)
  - TTS enable/disable toggle
  - System prompt configuration (sent to selected chat provider)
- [ ] Clarify provider usage:
  - Display: "Chat Provider: Venice.ai (default)" or "OpenAI"
  - Display: "TTS Provider: OpenAI (always)"
  - Explain that TTS always uses OpenAI regardless of chat provider
- [ ] Persist settings:
  - Save to backend (future: user accounts)
  - Local storage for now
- [ ] Apply settings to chat:
  - Use selected chat API provider (Venice/OpenAI)
  - TTS always uses OpenAI with selected voice

---

## Phase 6: Advanced Features

### 6.0 Image Generation

**Tasks:**
- [ ] Create `ImageGenerator` service:
  - Generate images from chat content
  - Generate images from prompts
  - Theme extraction from chat (word frequency analysis)
  - AI-generated image prompts (using Venice/OpenAI)
  - Fallback prompts if API fails
- [ ] Create `ImageGallery` component:
  - Display generated images
  - Image preview
  - Download images
  - Link images to chats
  - Image metadata (prompt, date, provider)
- [ ] Implement image generation:
  - OpenAI DALL-E integration
  - Venice image generation integration
  - Provider switching
  - Image download and save
  - Organized file naming
  - Error handling
- [ ] **Image Generation API**:
  - `POST /api/v1/chats/:id/images` - Generate images from chat
  - `POST /api/v1/prompts/:id/images` - Generate images from prompt
  - `GET /api/v1/images/:id` - Get image file
  - `DELETE /api/v1/images/:id` - Delete image

### 6.1 Text-to-Speech

**Tasks:**
- [ ] Create `AudioPlayer` component:
  - Play/pause controls
  - Progress bar
  - Volume control
  - Download audio file
  - Speed control (enhancement)
  - Multiple voice support per conversation (enhancement)
- [ ] Implement audio generation:
  - Generate audio from chat messages
  - Show progress during generation (segments, chunks)
  - Handle long conversations (intelligent chunking at punctuation)
  - Chunk splitting (max 1500 chars, prefer sentence boundaries)
  - Combine audio segments (ffmpeg or binary)
  - Save audio files with timestamps
  - Error handling with retries
  - Timeout handling
- [ ] **TTS Service Enhancements**:
  - Segment extraction from chat content
  - Handle role indicators (USER:, ASSISTANT:, DADDY:, BARRY:)
  - Skip system messages
  - Progress tracking (segment X of Y, chunk X of Y)
  - Retry logic with exponential backoff
  - Voice assignment per character (enhancement)
- [ ] Audio management:
  - List generated audio files
  - Delete old audio files
  - Play audio in browser
  - Audio file preview
  - Link audio to chat files

### 6.2 Chat Export

**Tasks:**
- [ ] Export chat to text file:
  - Format: User/Assistant messages
  - Include system prompt info
  - Include timestamps
  - Include word count
  - Include API provider used
  - Include prompt synopsis (if generated)
  - Download as .txt file
  - Timestamp-based filename: `YYYYMMDD_HHMMSS_dialogue_[N]words.txt`
- [ ] Export chat to markdown:
  - **Multiple format detection** (emoji format, CLI format, etc.)
  - Formatted markdown
  - Code blocks preserved
  - Proper heading structure
  - Download as .md file
  - Preserve conversation structure
- [ ] **Export Service**:
  - Format conversation for save
  - Generate metadata footer
  - Include prompt synopsis section
  - Handle different chat formats

### 6.3 Enhanced Features

**Tasks:**
- [ ] **Extended Dialogue Generation**:
  - Target word count input
  - Multi-segment generation
  - Progress tracking (words added, segments generated)
  - Real-time progress display
  - Interrupt handling (stop generation)
  - Completion options (save, keep, restore)
  - Smart continuation prompts
  - Character consistency maintenance
- [ ] **Continue Conversation**:
  - Add words to existing conversation
  - Show current word count
  - Optional user prompt to guide continuation
  - Progress tracking
  - Context-aware continuation
- [ ] **Auto-Extend Command**:
  - `auto [words]` command in chat
  - Default word count (1000)
  - Works within interactive chat
  - Progress display
  - Can be interrupted
- [ ] **Word Counting Service**:
  - Accurate word counting (excludes system messages)
  - Real-time word count display
  - Progress tracking for generation
  - Word count in filenames
  - Word count statistics
- [ ] Chat search:
  - Search within current chat
  - Search across all chats
  - Highlight search results
  - Advanced search (by date, word count, prompt)
- [ ] Message actions:
  - Edit user messages (regenerate response)
  - Delete messages
  - Copy message content
  - Regenerate assistant response
- [ ] Conversation management:
  - Clear conversation
  - Start new chat
  - Duplicate chat
  - Conversation folders/tags (enhancement)
  - Conversation templates (enhancement)

---

## Phase 7: Testing & Quality

### 7.1 Backend Testing

**Tasks:**
- [ ] Set up RSpec:
  - Test file storage configuration
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
  - File storage directories
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
- [ ] File storage setup:
  - Production data directories
  - Backup strategy
  - File permissions

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
5. **No hardcoding**: Discover from configuration files

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
  - Import chat files from `chatgpt1_0/chats/` directory
  - Import prompts from `chatgpt1_0/prompts/` directory
  - Import audio files metadata
  - Convert to new file format (JSON)
  - Preserve timestamps
- [ ] Validate migrated data:
  - Check all chats imported
  - Verify message order
  - Confirm prompts loaded

### Feature Parity

**Checklist:**
- [x] Chat with AI (Venice.ai default, OpenAI optional)
- [x] System prompts (sent to Venice.ai or selected chat provider)
- [x] Text-to-speech (always via OpenAI)
- [x] Audio generation from chats (OpenAI TTS)
- [x] Chat history saving
- [x] Prompt management
- [x] Voice selection (for OpenAI TTS)
- [x] Chat provider selection (Venice/OpenAI - affects chat only, not TTS)

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

