#!/bin/bash
# Smart Commit Installer
# https://github.com/clark-14/smart-commit

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://raw.githubusercontent.com/clark-14/smart-commit/main/smart-commit.sh"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="smart-commit.sh"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"

# Functions
print_header() {
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════╗"
    echo "║                                       ║"
    echo "║         Smart Commit Installer        ║"
    echo "║                                       ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

check_requirements() {
    print_step "Checking requirements..."
    
    # Check zsh
    if ! command -v zsh &> /dev/null; then
        print_error "zsh is not installed"
        echo -e "  Install it with: ${CYAN}brew install zsh${NC} (macOS) or ${CYAN}apt install zsh${NC} (Linux)"
        exit 1
    fi
    print_success "zsh found"
    
    # Check git
    if ! command -v git &> /dev/null; then
        print_error "git is not installed"
        exit 1
    fi
    print_success "git found"
    
    # Check Ollama
    if ! command -v ollama &> /dev/null; then
        print_warning "Ollama is not installed (optional but recommended)"
        echo -e "  Install it with: ${CYAN}curl -fsSL https://ollama.ai/install.sh | sh${NC}"
        echo -e "  Then run: ${CYAN}ollama pull mistral${NC}"
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    else
        print_success "Ollama found"
        
        # Check if mistral model is available
        if ! ollama list | grep -q mistral; then
            print_warning "Mistral model not found"
            echo -e "  Run: ${CYAN}ollama pull mistral${NC}"
        else
            print_success "Mistral model available"
        fi
    fi
}

create_install_dir() {
    print_step "Creating installation directory..."
    
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
        print_success "Created $INSTALL_DIR"
    else
        print_success "Directory already exists"
    fi
}

download_script() {
    print_step "Downloading Smart Commit..."
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$REPO_URL" -o "$SCRIPT_PATH"
    elif command -v wget &> /dev/null; then
        wget -q "$REPO_URL" -O "$SCRIPT_PATH"
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    chmod +x "$SCRIPT_PATH"
    print_success "Downloaded and made executable"
}

setup_path() {
    print_step "Setting up PATH..."
    
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        shell_rc="$HOME/.bashrc"
    else
        print_warning "Could not find shell configuration file"
        return
    fi
    
    # Check if PATH already includes the directory
    if ! grep -q "$INSTALL_DIR" "$shell_rc" 2>/dev/null; then
        echo "" >> "$shell_rc"
        echo "# Smart Commit" >> "$shell_rc"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$shell_rc"
        print_success "Added $INSTALL_DIR to PATH in $shell_rc"
    else
        print_success "PATH already configured"
    fi
}

setup_aliases() {
    print_step "Setting up aliases..."
    
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        shell_rc="$HOME/.bashrc"
    else
        print_warning "Could not find shell configuration file"
        echo -e "  ${YELLOW}Add this manually to your shell config:${NC}"
        echo -e "  ${CYAN}alias sc='smart-commit.sh'${NC}"
        echo -e "  ${CYAN}git config --global alias.sc '!smart-commit.sh'${NC}"
        return
    fi
    
    # Add shell alias if not exists
    if ! grep -q "alias sc=" "$shell_rc" 2>/dev/null; then
        echo "" >> "$shell_rc"
        echo "# Smart Commit shell alias" >> "$shell_rc"
        echo "alias sc='smart-commit.sh'" >> "$shell_rc"
        print_success "Added shell alias 'sc'"
    else
        print_success "Shell alias already configured"
    fi
    
    # Add git alias
    if ! git config --global --get alias.sc &> /dev/null; then
        git config --global alias.sc '!smart-commit.sh'
        print_success "Added git alias 'git sc'"
    else
        print_success "Git alias already configured"
    fi
}

download_example_prompts() {
    print_step "Downloading example prompts..."
    
    local prompt_dir="$HOME/.config/smart-commit/prompts"
    mkdir -p "$prompt_dir"
    
    local base_url="https://raw.githubusercontent.com/clark-14/smart-commit/main/prompts"
    local prompts=("file_prompt.txt" "final_prompt_verbose.txt" "final_prompt_nonverbose.txt")
    
    for prompt in "${prompts[@]}"; do
        if [ ! -f "$prompt_dir/$prompt" ]; then
            if curl -fsSL "$base_url/$prompt" -o "$prompt_dir/$prompt" 2>/dev/null; then
                print_success "Downloaded $prompt"
            else
                print_warning "Could not download $prompt (using defaults)"
            fi
        else
            print_success "$prompt already exists"
        fi
    done
}

print_next_steps() {
    echo ""
    echo -e "${GREEN}${BOLD}✓ Installation complete!${NC}"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo ""
    echo -e "1. ${CYAN}Restart your terminal${NC} or run:"
    echo -e "   ${BLUE}source ~/.zshrc${NC}"
    echo ""
    echo -e "2. ${CYAN}Verify installation:${NC}"
    echo -e "   ${BLUE}smart-commit.sh --config${NC}"
    echo ""
    echo -e "3. ${CYAN}Use it!${NC}"
    echo -e "   ${BLUE}git sc${NC}           # Git alias"
    echo -e "   ${BLUE}sc${NC}               # Shell alias"
    echo -e "   ${BLUE}smart-commit.sh${NC}  # Direct command"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo -e "   ${BLUE}git sc --fast${NC}      # Quick commit"
    echo -e "   ${BLUE}git sc --verbose${NC}   # Detailed commit"
    echo -e "   ${BLUE}git sc --no-ai${NC}     # Manual mode"
    echo ""
    echo -e "${BOLD}Documentation:${NC}"
    echo -e "   ${CYAN}https://github.com/clark-14/smart-commit${NC}"
    echo ""
    echo -e "${YELLOW}If Ollama is not installed:${NC}"
    echo -e "   ${BLUE}curl -fsSL https://ollama.ai/install.sh | sh${NC}"
    echo -e "   ${BLUE}ollama pull mistral${NC}"
    echo ""
    echo -e "Happy committing! 🚀"
}

# Main installation
main() {
    print_header
    
    check_requirements
    create_install_dir
    download_script
    setup_path
    setup_aliases
    download_example_prompts
    print_next_steps
}

# Run main function
main