# Smart Commit

> AI-powered conventional commits with interactive file staging

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/clark-14/smart-commit) [![Stars](https://img.shields.io/github/stars/clark-14/smart-commit?style=social)](https://github.com/clark-14/smart-commit/stargazers)

## ✨ Features

- 🧠 **AI-Powered** - Analyzes your changes and generates conventional commit messages
- 📝 **Smart File Staging** - Interactive UI to add files if you forgot `git add`
- ⚡ **Fast Mode** - One-command commit for quick workflows
- 📖 **Verbose Mode** - Detailed commit messages with explanations
- 🎨 **Beautiful UI** - Clean, colorful terminal interface
- 🔄 **Regenerate** - Not happy? Regenerate the message instantly
- ⚙️ **Configurable** - Customize prompts and behavior

## 🚀 Quick Start

### Prerequisites

- **zsh** (macOS default, or install on Linux)
- **git** (obviously 😉)
- **[Ollama](https://ollama.ai/)** with `mistral` model

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull mistral model
ollama pull mistral
```

### Installation

**Option 1: One-liner (Recommended)**

```bash
curl -sSL https://raw.githubusercontent.com/clark-14/smart-commit/main/install.sh | bash
```

**Option 2: Manual**

```bash
# Clone the repo
git clone https://github.com/clark-14/smart-commit.git
cd smart-commit

# Make executable
chmod +x smart-commit.sh

# Move to PATH
sudo mv smart-commit.sh /usr/local/bin/smart-commit
```

**Option 3: Git alias (Recommended)**

```bash
# Add to git config
git config --global alias.sc '!smart-commit.sh'

# Now use it with:
git sc
```

**Option 4: Shell alias**

```bash
# Add to ~/.zshrc
echo 'alias sc="smart-commit.sh"' >> ~/.zshrc
source ~/.zshrc

# Now use it with:
sc
```

## 📖 Usage

### Basic Usage

```bash
git sc                    # Interactive mode with AI
# or
sc                        # If using shell alias
```

### Flags

```bash
git sc --fast             # Auto-commit with AI (no confirmation)
git sc --verbose          # AI with detailed explanation
git sc --no-ai            # Manual commit (no AI)
git sc --no-test          # Exclude test files from analysis
git sc --config           # Show current configuration
```

### Examples

**Scenario 1: You forgot to `git add`**

```bash
# No files staged yet
$ git sc

⚠ No files staged for commit

Modified/Untracked files:
1) M src/app.js
2) M src/utils.js
3) ? README.md

Add files to commit:
  a) Add all
  1,2,3) Add specific files (comma-separated)
  q) Quit

Your choice: 1,3
✓ Staged: src/app.js
✓ Staged: README.md
```

**Scenario 2: Quick commit**

```bash
$ git add .
$ git sc --fast

🧠 Analyzing 3 file(s)...
🧠 Generating commit message...
✓ Commit successful!
```

**Scenario 3: Detailed commit**

```bash
$ git add .
$ git sc --verbose

📄 src/auth.service.ts
  → Added JWT token validation middleware

📄 src/user.controller.ts
  → Updated user login endpoint with token support

🧠 Generating commit message...

────────────────────────────────────────
Proposed commit message:

feat(auth): add JWT authentication

Implemented token-based authentication using JWT. The middleware
validates tokens on protected routes and handles expiration.
This improves security and enables stateless sessions.

────────────────────────────────────────

[c] commit   [e] edit   [r] regenerate   [d] discard: c
✓ Commit successful!
```

## ⚙️ Configuration

### Custom Prompts

Create custom prompts in `~/.config/smart-commit/prompts/`:

```bash
# View current configuration
git sc --config

# Create custom prompts directory
mkdir -p ~/.config/smart-commit/prompts

# Edit file analysis prompt
vim ~/.config/smart-commit/prompts/file_prompt.txt

# Edit final commit message prompt (non-verbose)
vim ~/.config/smart-commit/prompts/final_prompt_nonverbose.txt

# Edit final commit message prompt (verbose)
vim ~/.config/smart-commit/prompts/final_prompt_verbose.txt
```

See [prompts/](https://claude.ai/chat/prompts/) directory for examples.

### Environment Variables

You can customize behavior with environment variables in `~/.zshrc`:

```bash
# Ollama model to use
export SMART_COMMIT_MODEL="mistral"

# Timeout for AI generation (seconds)
export SMART_COMMIT_TIMEOUT=60
```

## 🎯 Supported Commit Types

Following [Conventional Commits](https://www.conventionalcommits.org/):

|Type|Description|
|---|---|
|`feat`|New feature|
|`fix`|Bug fix|
|`docs`|Documentation changes|
|`style`|Code style (formatting, semicolons, etc.)|
|`refactor`|Code refactoring|
|`perf`|Performance improvements|
|`test`|Adding tests|
|`chore`|Maintenance tasks|
|`ci`|CI/CD changes|
|`build`|Build system changes|

## 🛠 Troubleshooting

### "Ollama not found"

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh
ollama pull mistral
```

### "AI generation failed"

```bash
# Check if Ollama is running
ollama list

# Test if model is available
ollama run mistral "Hello"

# Restart Ollama
ollama serve
```

### "Command not found: smart-commit"

```bash
# Option 1: Check if it's in PATH
which smart-commit.sh

# Option 2: Check PATH variable
echo $PATH

# Option 3: Use full path
~/path/to/smart-commit.sh

# Option 4: Add to PATH in ~/.zshrc
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Option 5: Create shell alias
echo 'alias sc="~/path/to/smart-commit.sh"' >> ~/.zshrc
source ~/.zshrc
```

### Colors not working

```bash
# Make sure you're using a terminal that supports ANSI colors
# iTerm2, Terminal.app, Alacritty, Hyper, etc.

# Test colors
echo -e "\033[0;32mGreen\033[0m"
```

### Script doesn't have execute permission

```bash
chmod +x ~/path/to/smart-commit.sh
```

## 🤝 Contributing

Contributions are welcome! Here's how:

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing`)
3. Commit using **this tool** 😉 (`git sc`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

## 💖 Support

If you find this tool useful, consider:

- ⭐ [Star the repo](https://github.com/clark-14/smart-commit)
- 🐛 [Report bugs](https://github.com/clark-14/smart-commit/issues)
- 💡 [Request features](https://github.com/clark-14/smart-commit/issues)
- 🔀 [Contribute code](https://github.com/clark-14/smart-commit/pulls)

## 📄 License

MIT License

Copyright (c) 2025 Giuseppe Gusmeroli

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## 🙏 Acknowledgments

- Powered by [Ollama](https://ollama.ai/)
- Based on [Conventional Commits](https://www.conventionalcommits.org/)

---

**Made by [Giuseppe Gusmeroli](https://github.com/clark-14)**
