#!/bin/zsh
# clark conventional commit helper - Enhanced version
# https://github.com/clark-14/smart-commit

# === CONFIGURATION ===
# You can override prompts by creating files in ~/.config/smart-commit/prompts/
PROMPT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/smart-commit/prompts"

# === DEFAULT PROMPT TEMPLATES ===
# These are used if external files are not found

DEFAULT_FILE_PROMPT='Analyze this git diff for a single file.
${ACCUMULATED_CHANGES}
<current_diff file="${file_name}">
${FILE_DIFF}
</current_diff>

Describe what changed in ONE sentence (max 150 chars). Be factual and impersonal.
Examples: '\''Added user authentication'\'', '\''Fixed race condition'\'', '\''Updated validation'\'''

DEFAULT_FINAL_PROMPT_VERBOSE='You are a commit message expert. Analyze ALL the file changes below and generate a comprehensive conventional commit message.

${ACCUMULATED_CHANGES}

CRITICAL: Your message must reflect ALL ${file_count} files listed above, not just some.

Output format:
Line 1: ${TYPE}${SCOPE}: <comprehensive description covering all changes> (max 72 chars)
Line 2: (empty)
Lines 3+: Detailed explanation (2-4 sentences, impersonal tone)

Requirements:
- Start with non capital letter
- The first line MUST summarize changes across all files
- Use imperative mood ('\''add'\'', '\''fix'\'', '\''refactor'\'')
- Be specific about what changed
- Mention key areas if multiple components affected'

DEFAULT_FINAL_PROMPT_NONVERBOSE='You are a commit message expert. Analyze ALL the file changes below.

${ACCUMULATED_CHANGES}

CRITICAL: Generate ONE commit message that covers ALL ${file_count} files above.

Requirements:
- Format: ${TYPE}${SCOPE}: <description>
- Start with non capital letter
- Max 72 characters
- Must represent ALL changes, not just one file
- Use imperative mood ('\''add'\'' not '\''added'\'')
- Be specific and comprehensive

If changes span multiple areas, mention the main theme or use '\''multiple'\'' scope.

Output ONLY the commit message line (no preamble, no explanation):'

# === PROMPT LOADING FUNCTIONS ===
get_file_prompt() {
    local external_file="$PROMPT_DIR/file_prompt.txt"
    if [[ -f "$external_file" ]]; then
        cat "$external_file"
    else
        echo "$DEFAULT_FILE_PROMPT"
    fi
}

get_final_prompt_verbose() {
    local external_file="$PROMPT_DIR/final_prompt_verbose.txt"
    if [[ -f "$external_file" ]]; then
        cat "$external_file"
    else
        echo "$DEFAULT_FINAL_PROMPT_VERBOSE"
    fi
}

get_final_prompt_nonverbose() {
    local external_file="$PROMPT_DIR/final_prompt_nonverbose.txt"
    if [[ -f "$external_file" ]]; then
        cat "$external_file"
    else
        echo "$DEFAULT_FINAL_PROMPT_NONVERBOSE"
    fi
}

# === COLORS ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# === FLAGS ===
NO_AI=false
VERBOSE=false
FAST=false
NO_TEST=false
TIMEOUT=60
SHOW_CONFIG=false

for arg in "$@"; do
    case "$arg" in
        --no-ai) NO_AI=true ;;
        --verbose) VERBOSE=true ;;
        --fast) FAST=true ;;
        --no-test) NO_TEST=true ;;
        --config) SHOW_CONFIG=true ;;
    esac
done

# === UTILITIES ===
log_info() { echo "${CYAN}🔧${NC} $1"; }
log_generating() { echo "🧠 ${NC} $1"; }
log_ok() { echo "${GREEN}✓${NC} $1"; }
log_warn() { echo "${YELLOW}⚠ ${NC} $1"; }
log_err() { echo "${RED}✗${NC} $1"; }

divider() { print -P "%F{green}────────────────────────────────────────%f"; }

# Show configuration
if $SHOW_CONFIG; then
    echo "${BOLD}Smart Commit Configuration${NC}"
    echo "Prompt directory: $PROMPT_DIR"
    echo ""
    echo "Custom prompts status:"
    
    local custom_found=false
    for prompt_file in "file_prompt.txt" "final_prompt_verbose.txt" "final_prompt_nonverbose.txt"; do
        if [[ -f "$PROMPT_DIR/$prompt_file" ]]; then
            echo "  ${GREEN}✓${NC} $prompt_file (custom)"
            custom_found=true
        else
            echo "  ${GRAY}○${NC} $prompt_file (default)"
        fi
    done
    
    echo ""
    if ! $custom_found; then
        echo "${CYAN}To customize prompts:${NC}"
        echo "  mkdir -p $PROMPT_DIR"
        echo "  vim $PROMPT_DIR/file_prompt.txt"
    else
        echo "${CYAN}To reset to defaults:${NC}"
        echo "  rm -rf $PROMPT_DIR"
    fi
    exit 0
fi

# Expand template variables
expand_template() {
    local template="$1"
    eval "cat <<TEMPLATE_EOF
$template
TEMPLATE_EOF"
}

# Call Ollama with timeout and retry
call_ollama() {
    local prompt="$1"
    local max_attempts=3

    for attempt in {1..$max_attempts}; do
        local output=""

        if command -v timeout >/dev/null 2>&1; then
            output=$(timeout $TIMEOUT ollama run mistral "$prompt" 2>/dev/null)
        elif command -v gtimeout >/dev/null 2>&1; then
            output=$(gtimeout $TIMEOUT ollama run mistral "$prompt" 2>/dev/null)
        else
            output=$(ollama run mistral "$prompt" 2>/dev/null)
        fi

        [[ $? -eq 0 && -n "$output" ]] && { echo "$output"; return 0; }
        [[ $attempt -lt $max_attempts ]] && log_warn "Attempt $attempt failed, retrying..."
    done

    return 1
}

# === VALIDATION ===
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_err "Not a git repository"
    exit 1
fi

# === SMART GIT ADD ===
STAGED_FILES=(${(f)"$(git diff --cached --name-only 2>/dev/null)"})
UNSTAGED_FILES=(${(f)"$(git diff --name-only 2>/dev/null)"})
UNTRACKED_FILES=(${(f)"$(git ls-files --others --exclude-standard 2>/dev/null)"})

ALL_UNSTAGED=("${UNSTAGED_FILES[@]}" "${UNTRACKED_FILES[@]}")

if [[ ${#STAGED_FILES[@]} -eq 0 ]]; then
    if [[ ${#ALL_UNSTAGED[@]} -eq 0 ]]; then
        log_err "No changes to commit"
        exit 1
    fi

    if ! $FAST; then
        log_warn "No files staged for commit"
        echo
        print -P "%F{yellow}Modified/Untracked files:%f"

        local i=1
        local -A file_map
        for file in "${UNSTAGED_FILES[@]}"; do
            print -P "%F{cyan}$i)%f %F{yellow}M%f $file"
            file_map[$i]=$file
            ((i++))
        done
        for file in "${UNTRACKED_FILES[@]}"; do
            print -P "%F{cyan}$i)%f %F{green}?%f $file"
            file_map[$i]=$file
            ((i++))
        done

        echo
        print -P "%F{yellow}Add files to commit:%f"
        print "  a) Add all"
        print "  1,2,3) Add specific files (comma-separated)"
        print "  q) Quit"
        echo

        read "add_choice?Your choice: "

        case "$add_choice" in
            a|A)
                git add -A
                log_ok "All files staged"
                ;;
            q|Q)
                log_warn "Cancelled"
                exit 0
                ;;
            *)
                IFS=',' read -rA selected <<< "$add_choice"
                local added=0
                for num in "${selected[@]}"; do
                    num=$(echo "$num" | xargs)
                    if [[ -n "${file_map[$num]}" ]]; then
                        git add "${file_map[$num]}"
                        log_ok "Staged: ${file_map[$num]}"
                        ((added++))
                    fi
                done

                if [[ $added -eq 0 ]]; then
                    log_err "No valid files selected"
                    exit 1
                fi
                ;;
        esac
        echo
    else
        git add -A
        log_ok "All files staged (fast mode)"
    fi
elif [[ ${#ALL_UNSTAGED[@]} -gt 0 ]] && ! $FAST; then
    log_info "Found ${#STAGED_FILES[@]} staged and ${#ALL_UNSTAGED[@]} unstaged files"
    echo

    print -P "%F{green}Staged:%f"
    for file in "${STAGED_FILES[@]}"; do
        print -P "  %F{green}✓%f $file"
    done
    echo

    print -P "%F{yellow}Unstaged:%f"
    local i=1
    local -A file_map
    for file in "${UNSTAGED_FILES[@]}"; do
        print -P "%F{cyan}$i)%f %F{yellow}M%f $file"
        file_map[$i]=$file
        ((i++))
    done
    for file in "${UNTRACKED_FILES[@]}"; do
        print -P "%F{cyan}$i)%f %F{green}?%f $file"
        file_map[$i]=$file
        ((i++))
    done
    echo

    read "add_more?Add more files? (a)ll / (1,2,3) specific / (n)o: "

    case "$add_more" in
        a|A)
            git add -A
            log_ok "All remaining files staged"
            echo
            ;;
        n|N|"")
            ;;
        *)
            IFS=',' read -rA selected <<< "$add_more"
            for num in "${selected[@]}"; do
                num=$(echo "$num" | xargs)
                if [[ -n "${file_map[$num]}" ]]; then
                    git add "${file_map[$num]}"
                    log_ok "Staged: ${file_map[$num]}"
                fi
            done
            echo
            ;;
    esac
fi

if git diff --cached --quiet; then
    log_err "No staged changes to commit"
    exit 1
fi

# === STAGED FILES SUMMARY ===
if ! $FAST; then
    print -P "%F{cyan}Files to commit:%f"
    git diff --cached --name-status
    echo
fi

# === SELECT COMMIT TYPE ===
if ! $FAST; then
    print -P "%F{yellow}Select commit type:%f"
    print "1) feat      2) fix"
    print "3) docs      4) style"
    print "5) refactor  6) perf"
    print "7) test      8) chore"
    print "9) ci        10) build"
    echo
    read "type_choice?Enter choice (1-10): "
else
    type_choice=1
fi

case $type_choice in
    1) TYPE="feat" ;;
    2) TYPE="fix" ;;
    3) TYPE="docs" ;;
    4) TYPE="style" ;;
    5) TYPE="refactor" ;;
    6) TYPE="perf" ;;
    7) TYPE="test" ;;
    8) TYPE="chore" ;;
    9) TYPE="ci" ;;
    10) TYPE="build" ;;
    *) log_err "Invalid choice"; exit 1 ;;
esac

# === SCOPE ===
if ! $FAST; then
    read "scope?Enter scope (optional): "
else
    scope=""
fi

SCOPE=""
[[ -n "$scope" ]] && SCOPE="($scope)"

# === AI GENERATION ===
COMMIT_MSG=""
AI_EXPLANATION=""

if ! $NO_AI && command -v ollama >/dev/null 2>&1; then
    if $NO_TEST; then
        CHANGED_FILES=(${(f)"$(git diff --cached --name-only | grep -v '/test/')"})
    else
        CHANGED_FILES=(${(f)"$(git diff --cached --name-only)"})
    fi
    total_files=${#CHANGED_FILES[@]}

    if [[ $total_files -gt 0 ]]; then
        ! $FAST && log_info "Analyzing $total_files file(s)..." && echo

        ACCUMULATED_CHANGES=""

        # Analyze each file
        for file_name in $CHANGED_FILES; do
            ! $FAST && print -P "%F{green}📄 $file_name%f"

            FILE_DIFF=$(git diff --cached -U3 -- "$file_name")
            
            FILE_PROMPT_TEMPLATE=$(get_file_prompt)
            FILE_PROMPT=$(expand_template "$FILE_PROMPT_TEMPLATE")

            change_desc=$(call_ollama "$FILE_PROMPT")

            if [[ -n "$change_desc" ]]; then
                change_desc=$(echo "$change_desc" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
                ! $FAST && print -P "%F{240}  → $change_desc%f" && echo
                ACCUMULATED_CHANGES+="<file name=\"$file_name\">
$change_desc
</file>
"
            fi
        done

        # Generate final message
        ! $FAST && log_generating "Generating commit message..."

        file_count=$(echo "$ACCUMULATED_CHANGES" | grep -c '<file name=')

        if $VERBOSE; then
            FINAL_PROMPT_TEMPLATE=$(get_final_prompt_verbose)
        else
            FINAL_PROMPT_TEMPLATE=$(get_final_prompt_nonverbose)
        fi
        
        FINAL_PROMPT=$(expand_template "$FINAL_PROMPT_TEMPLATE")

        AI_OUTPUT=$(call_ollama "$FINAL_PROMPT")

        if [[ -n "$AI_OUTPUT" ]]; then
            if $VERBOSE; then
                COMMIT_MSG=$(echo "$AI_OUTPUT" | head -n 1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
                AI_EXPLANATION=$(echo "$AI_OUTPUT" | tail -n +3 | sed '/^[[:space:]]*$/d')
                [[ -n "$AI_EXPLANATION" ]] && COMMIT_MSG="$COMMIT_MSG

$AI_EXPLANATION"
            else
                COMMIT_MSG=$(echo "$AI_OUTPUT" | sed '/^[[:space:]]*$/d' | head -n 1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

                if [[ ! "$COMMIT_MSG" =~ ^${TYPE} ]]; then
                    log_warn "AI didn't respect format, fixing..."
                    COMMIT_MSG="${TYPE}${SCOPE}: ${COMMIT_MSG}"
                fi
            fi
        fi
    fi
fi

# === FALLBACK ===
if [[ -z "$COMMIT_MSG" ]]; then
    $NO_AI && log_warn "AI disabled (--no-ai)" || log_warn "AI generation failed"

    if $FAST; then
        COMMIT_MSG="${TYPE}${SCOPE}: update"
    else
        read "description?Enter description: "
        [[ -z "$description" ]] && log_err "Description cannot be empty" && exit 1
        COMMIT_MSG="${TYPE}${SCOPE}: ${description}"
    fi
fi

# === FAST MODE: COMMIT DIRECTLY ===
if $FAST; then
    git commit -m "$COMMIT_MSG"
    log_ok "Commit successful!"
    exit 0
fi

# === INTERACTIVE MENU ===
while true; do
    echo
    divider
    print -P "%F{green}%BProposed commit message:%b%f"
    echo
    echo "$COMMIT_MSG"
    echo
    divider
    echo

    print -P "%F{green}[c]%f commit   %F{cyan}[e]%f edit   %F{yellow}[r]%f regenerate   %F{red}[d]%f discard : "
    read choice

    case "$choice" in
        c|C)
            git commit -m "$COMMIT_MSG"
            log_ok "Commit successful!"
            exit 0
            ;;
        e|E)
            TEMP_FILE=$(mktemp)
            echo "$COMMIT_MSG" > "$TEMP_FILE"
            ${EDITOR:-vim} "$TEMP_FILE"
            git commit -F "$TEMP_FILE"
            rm -f "$TEMP_FILE"
            log_ok "Commit successful!"
            exit 0
            ;;
        r|R)
            log_info "Regenerating..."
            echo

            AI_OUTPUT=$(call_ollama "$FINAL_PROMPT")
            if [[ -n "$AI_OUTPUT" ]]; then
                if $VERBOSE; then
                    COMMIT_MSG=$(echo "$AI_OUTPUT" | head -n 1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
                    AI_EXPLANATION=$(echo "$AI_OUTPUT" | tail -n +3 | sed '/^[[:space:]]*$/d')
                    [[ -n "$AI_EXPLANATION" ]] && COMMIT_MSG="$COMMIT_MSG

$AI_EXPLANATION"
                else
                    COMMIT_MSG=$(echo "$AI_OUTPUT" | sed '/^[[:space:]]*$/d' | head -n 1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

                    if [[ ! "$COMMIT_MSG" =~ ^${TYPE} ]]; then
                        log_warn "AI didn't respect format, fixing..."
                        COMMIT_MSG="${TYPE}${SCOPE}: ${COMMIT_MSG}"
                    fi
                fi
            else
                log_warn "Regeneration failed, keeping previous message"
            fi
            continue
            ;;
        d|D|q|Q)
            log_warn "Commit cancelled"
            exit 0
            ;;
        *)
            log_warn "Invalid choice"
            continue
            ;;
    esac
done