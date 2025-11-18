# Feature Analysis - Old Application vs New Architecture

## Comprehensive Feature Inventory

### 1. Chat & Conversation Features

#### ✅ Core Chat
- [x] Interactive chat sessions
- [x] Send messages to AI
- [x] Receive AI responses
- [x] Conversation history tracking
- [x] Clear conversation
- [x] Save conversation to file

#### ✅ Advanced Chat Features
- [x] **Extended Dialogue Generation**: Generate dialogue with target word count
  - User specifies target word count (default: 2000)
  - System generates multiple segments until target reached
  - Shows progress (words added, segments generated)
  - Can be interrupted (Ctrl+C)
  - Offers save/keep/restore options after completion

- [x] **Continue Conversation**: Add more words to existing conversation
  - Shows current word count
  - User specifies additional words (default: 1000)
  - Optional user prompt to guide continuation
  - Generates continuation segments
  - Tracks progress

- [x] **Auto-Extend in Chat**: Command to auto-extend during chat session
  - `auto [words]` or `extend [words]` commands
  - Works within interactive chat mode
  - Default: 1000 words if not specified

- [x] **Word Counting**: Accurate word count tracking
  - Counts words in all non-system messages
  - Displays current/target word counts
  - Includes word count in saved filenames

- [x] **Opening Lines**: Auto-start conversations
  - Loads from `.opening_lines` files
  - Randomly selects opening line
  - Automatically sends to AI
  - Gets first response

#### ✅ Conversation Display
- [x] Roleplay response formatting (DADDY:, BARRY:, SAMMY:)
- [x] Text wrapping for display
- [x] Character emoji indicators
- [x] Conversation statistics display

---

### 2. Prompt Management

#### ✅ System Prompts
- [x] **Base System Prompts**: Loaded from `system_prompts.txt`
  - Always included in conversation
  - Provides base instructions/context
  - Can be customized per installation

- [x] **User Prompts**: Loaded from `.prompt` files
  - Stored in `prompts/` directory
  - Combined with base system prompts
  - Can be loaded by name or number
  - Preview functionality

#### ✅ Prompt Features
- [x] **Interactive Prompt Selection**:
  - List all available prompts
  - Show preview of each prompt
  - Browse full prompt content (`b[number]` or `b[name]`)
  - Load by number or name
  - Partial name matching
  - Search functionality

- [x] **Prompt Loading**:
  - Load prompt by name (`-prompt` flag)
  - Load default prompt (`first.prompt`)
  - Combine base + user prompts
  - Preserve API provider when loading

- [x] **Prompt Synopsis Generation**:
  - Uses Venice.ai to analyze conversation
  - Generates synopsis of prompts used
  - Includes in saved chat files
  - Analyzes system prompts, characters, themes, style

- [x] **Opening Lines Files**:
  - `.opening_lines` files (one line per opening)
  - Random selection
  - Auto-send to start conversation

---

### 3. Text-to-Speech (TTS)

#### ✅ TTS Features
- [x] **Voice Selection**: OpenAI voices
  - Available: alloy, echo, fable, onyx, nova, shimmer
  - Default: echo
  - Interactive voice selection
  - Test voice functionality

- [x] **Audio Generation**:
  - Generate audio from chat files
  - Process entire chat conversations
  - Intelligent text chunking (max 1500 chars)
  - Chunk splitting at punctuation marks
  - Combine audio segments into single file
  - Uses ffmpeg if available, else binary concatenation

- [x] **TTS Service**:
  - Segment extraction from chat content
  - Handles role indicators (USER:, ASSISTANT:, etc.)
  - Skips system messages
  - Progress tracking during generation
  - Error handling with retries
  - Timeout handling

- [x] **Audio Management**:
  - Save to `audio_output/` directory
  - Timestamp-based filenames
  - Play audio files (platform-specific)
  - Custom output filename option

- [x] **TTS CLI**:
  - Standalone TTS application
  - Process chat files
  - Voice selection
  - Test voice
  - File preview

---

### 4. Image Generation

#### ✅ Image Generation Features
- [x] **Chat to Image**:
  - Generate images from chat file content
  - Extract themes from conversation
  - Generate image prompts using AI
  - Create 3 images per chat file

- [x] **Prompt to Image**:
  - Import prompts from `.prompt` files
  - Generate images from prompt content
  - Parse structured prompt files

- [x] **Image Providers**:
  - OpenAI DALL-E (dall-e-3 model)
  - Venice image generation
  - Provider switching

- [x] **Image Processing**:
  - Theme extraction from chat content
  - AI-generated image prompts
  - Fallback prompts if API fails
  - Image download and save
  - Organized file naming

- [x] **Image Generator Service**:
  - Clean chat content
  - Extract themes (word frequency analysis)
  - Generate descriptive prompts
  - Download and save images
  - Error handling

---

### 5. API Integration

#### ✅ Venice.ai Integration
- [x] **Chat Completions**:
  - Default provider for chat
  - Model: llama-3.3-70b
  - Venice-specific parameters:
    - `include_venice_system_prompt: false`
    - `top_p: 0.9`
    - `repetition_penalty: 1.1`
  - Custom temperature, max_tokens

- [x] **Image Generation**:
  - Venice image API
  - Style options
  - Size configuration

#### ✅ OpenAI Integration
- [x] **Chat Completions** (optional):
  - Model: gpt-3.5-turbo
  - Standard OpenAI parameters

- [x] **Text-to-Speech** (required):
  - Model: tts-1
  - Voices: alloy, echo, fable, onyx, nova, shimmer
  - Speed control
  - Output format: mp3
  - Retry logic with exponential backoff
  - Timeout handling

- [x] **Image Generation** (optional):
  - DALL-E 3
  - Size options
  - URL response format

#### ✅ API Management
- [x] **API Key Management**:
  - Load from files (`openAI_api_key`, `venice_api_key`)
  - Load from environment variables
  - Key validation
  - Status display

- [x] **Provider Switching**:
  - Switch between Venice and OpenAI
  - Validation (check if key exists)
  - Preserve conversation when switching
  - Display current provider

- [x] **Error Handling**:
  - Network timeouts
  - API errors
  - Retry logic
  - User-friendly error messages

---

### 6. File Management

#### ✅ Chat Files
- [x] **Save Conversations**:
  - Timestamp-based filenames
  - Word count in filename
  - Format: `YYYYMMDD_HHMMSS_dialogue_[N]words.txt`
  - Save to `chats/` directory
  - Includes conversation content
  - Includes metadata (word count, API provider, timestamp)
  - Includes prompt synopsis (if generated)

- [x] **Chat File Format**:
  - User messages: `USER: [content]`
  - Assistant messages: `AI: [content]`
  - Metadata footer
  - Prompt synopsis section

- [x] **File Operations**:
  - List chat files
  - Preview chat files
  - Select chat files for processing
  - Sort by modification time

#### ✅ Export Features
- [x] **Markdown Conversion**:
  - Convert `.txt` chat files to `.md`
  - Multiple format detection:
    - Emoji format (👤 User:, 🤖 Assistant:)
    - CLI header format
    - CLI format ("> " prefix)
  - Proper markdown formatting
  - Preserve structure

#### ✅ File Utilities
- [x] File preview functionality
- [x] Directory creation if missing
- [x] Timestamp-based naming
- [x] Word count in filenames

---

### 7. User Interface & Commands

#### ✅ Main Menu
- [x] Interactive menu system
- [x] Numbered options
- [x] Help commands (`?`, `help`)
- [x] Exit commands (`x`, `quit`, `exit`)
- [x] Status display

#### ✅ Chat Commands
- [x] `help` / `?` - Show help
- [x] `exit` / `quit` / `x` - End session
- [x] `clear` - Clear conversation
- [x] `save` - Save conversation
- [x] `voice on/off` - Toggle TTS
- [x] `auto [words]` - Auto-extend dialogue
- [x] `extend [words]` - Alias for auto
- [x] Natural message input

#### ✅ Voice Commands
- [x] Voice selection menu
- [x] Test voice (`t[number]`)
- [x] Voice preview
- [x] Current voice display

#### ✅ Prompt Commands
- [x] Browse prompts (`b[number]` or `b[name]`)
- [x] Load by number
- [x] Load by name (partial matching)
- [x] Preview display

---

### 8. Advanced Features

#### ✅ Conversation Analysis
- [x] **Prompt Synopsis Generation**:
  - Analyzes conversation using Venice.ai
  - Extracts:
    - System prompts/instructions
    - Character roles and personalities
    - Key themes and scenarios
    - Writing style/format instructions
  - Generates concise synopsis (< 500 words)
  - Includes in saved files

- [x] **Word Counting**:
  - Accurate word count
  - Excludes system messages
  - Real-time tracking
  - Progress display

#### ✅ Conversation Continuation
- [x] **Smart Continuation**:
  - Context-aware continuation prompts
  - Maintains character consistency
  - Varied prompt styles
  - Word count guidance
  - Natural dialogue flow

#### ✅ Error Recovery
- [x] Graceful interruption handling (Ctrl+C)
- [x] Conversation state preservation
- [x] Retry logic for API calls
- [x] Error messages with context
- [x] Fallback options

---

### 9. Configuration & Settings

#### ✅ Settings
- [x] API provider selection
- [x] Voice selection
- [x] TTS enable/disable
- [x] Default prompt configuration
- [x] Opening lines configuration

#### ✅ Defaults
- [x] Default API provider: Venice
- [x] Default voice: echo
- [x] Default prompt: `first.prompt`
- [x] Default opening lines: `first.opening_lines`

---

## Missing Features in Current Implementation Plan

### ❌ Not Yet Covered

1. **Opening Lines Feature**:
   - `.opening_lines` files
   - Random selection
   - Auto-send to start conversation
   - Need to add to Phase 5

2. **Extended Dialogue Generation**:
   - Target word count generation
   - Multi-segment generation
   - Progress tracking
   - Need to add to Phase 5

3. **Continue Conversation**:
   - Add words to existing conversation
   - Optional user prompt
   - Need to add to Phase 5

4. **Auto-Extend Command**:
   - `auto [words]` command in chat
   - Need to add to Phase 5

5. **Prompt Synopsis Generation**:
   - AI analysis of conversation
   - Extract prompt strategy
   - Need to add to Phase 6

6. **Image Generation**:
   - Chat to image
   - Prompt to image
   - Theme extraction
   - Need to add to Phase 6

7. **Markdown Export**:
   - Convert chats to Markdown
   - Multiple format detection
   - Need to add to Phase 6

8. **Word Counting**:
   - Accurate word counting
   - Real-time display
   - Progress tracking
   - Need to add throughout

9. **Roleplay Formatting**:
   - Character name formatting (DADDY:, BARRY:)
   - Special display formatting
   - Need to add to Phase 5

10. **Venice Parameters**:
    - `include_venice_system_prompt: false`
    - `top_p`, `repetition_penalty`
    - Need to add to Phase 2

---

## Recommendations for New Architecture

### Enhancements to Make

1. **More Sophisticated Prompt Management**:
   - Prompt versioning
   - Prompt categories/tags
   - Prompt search and filtering
   - Prompt templates
   - Prompt sharing/export

2. **Better Conversation Management**:
   - Conversation folders/tags
   - Conversation search
   - Conversation templates
   - Conversation branching
   - Conversation comparison

3. **Enhanced TTS**:
   - Multiple voice per conversation
   - Voice assignment per character
   - Speed control
   - Pause insertion
   - Background music option

4. **Advanced Image Generation**:
   - Image gallery per conversation
   - Image-to-image generation
   - Style transfer
   - Batch generation
   - Image editing

5. **Better Analytics**:
   - Conversation statistics
   - Word count trends
   - Prompt effectiveness analysis
   - Usage analytics
   - Export analytics

6. **Collaboration Features**:
   - Share conversations
   - Collaborative editing
   - Comments/annotations
   - Version history

7. **UI Improvements**:
   - Real-time streaming responses
   - Markdown rendering
   - Code syntax highlighting
   - Image inline display
   - Audio inline playback

8. **Performance**:
   - Response streaming
   - Background processing
   - Caching
   - Optimistic updates
   - Progressive loading

