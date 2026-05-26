export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

## pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

## homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

## poetry
export PATH="/Users/quinnweber/.local/bin:$PATH"

## nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

## direnv - loads .envrc files automatically
eval "$(direnv hook zsh)"

## bearcli - command line interface for Bear app
alias bearcli='/Applications/Bear.app/Contents/MacOS/bearcli'

## go utilities
function gocov() {
    # Define some color codes
    GREEN="\e[32m"
    CYAN="\e[36m"
    BOLD="\e[1m"
    RESET="\e[0m"

    local root_module="${1}"
    root_module=$(go list -m)
    echo "Testing for: ${BOLD}${CYAN}$root_module${RESET}"

    # 1. Gather all changed .go files compared to 'main'
    local changed_files=()
    while IFS= read -r f; do
        changed_files+=("$f")
    done < <(
        {
            git diff --name-only --diff-filter=ACMRTUXB "$(git merge-base HEAD main)";
            git diff --name-only;  # unstaged changes
            git diff --cached --name-only;  # staged but uncommitted changes
            git ls-files --others --exclude-standard;  # untracked changes
        } | grep -E '\.go$' | sort -u || true
    )

    if [[ "${#changed_files[@]}" -eq 0 ]]; then
        echo "No changed .go files found compared to 'master'; skipping coverage."
        return 0
    fi

    # 2. Map each file to its full import path (root_module + directory)
    local pkgs=()
    while IFS= read -r dir; do
        pkgs+=("$root_module/$dir")
    done < <(printf "%s\n" "${changed_files[@]}" | xargs -n1 dirname | sort -u)

    if [[ "${#pkgs[@]}" -eq 0 ]]; then
        echo "No unique packages found among changed files."
        return 0
    fi

    # 3. For each deduplicated package, gather possible test targets (pkg, pkg/test, pkg/tests)
    # assuming the package has a test file in the same directory
    local test_targets=()
    for pkg in "${pkgs[@]}"; do
        local sub_packages
        sub_packages=$(go list "$pkg/..." 2>/dev/null | grep -E "^${pkg}(/test|/tests)?$" | grep -v "mocks" || true)
        if [[ -n "$sub_packages" ]]; then
            while IFS= read -r line; do
                test_targets+=("$line")
            done <<<"$sub_packages"
        fi
    done

    if [[ "${#test_targets[@]}" -eq 0 ]]; then
        echo "No testable packages found among changed files."
        return 0
    fi
    echo "Testable packages: ${test_targets[*]}"

    # 4. Build a comma-separated string of all deduplicated packages for -coverpkg
    local coverpkg_str=""
    coverpkg_str=$(printf "%s\n" "${pkgs[@]}" | sort -u | tr '\n' ',' | sed 's/,$//')

    # 5. Run tests in one pass, with coverage
    local coverage_file=$(mktemp)
    local coverage_html="$(mktemp).html"

    echo -e "${BOLD}${CYAN}==> Changed packages:${RESET}"
    printf "   %s\n" ${pkgs[@]}
    echo

    echo -e "${BOLD}${CYAN}==> Test targets:${RESET}"
    if [[ ${#test_targets[@]} -eq 0 ]]; then
        echo -e "   ${GREEN}(No test targets found)${RESET}"
    else
        printf "   %s\n" "${test_targets[@]}"
    fi
    echo

    GOEXPERIMENT=boringcrypto go test \
        -coverpkg="$coverpkg_str" \
        -coverprofile="$coverage_file" \
        -timeout=600s \
        -count=1 \
        "${test_targets[@]}" || {
        echo "One or more tests failed. Coverage data may be incomplete."
        return 1
    }

    # 6. Generate HTML coverage and open in default browser
    go tool cover -html="$coverage_file" -o $coverage_html
    echo "Opening generated report: $coverage_html"
    open $coverage_html
}

function golint() {
    local base_branch="${1:-main}"

    # Get list of changed Go files
    local changed_files=$(git diff --name-only --diff-filter=ACMR "${base_branch}...HEAD" | grep '\.go$' 2>/dev/null)

    if [[ -z "$changed_files" ]]; then
        echo "No Go files have changed relative to ${base_branch}"
        return 0
    fi

    echo "Linting changed Go files relative to ${base_branch}:"
    echo "$changed_files" | sed 's/^/  - /'
    echo ""

    # Extract unique directories from changed files and run golangci-lint on each
    local dirs=$(echo "$changed_files" | xargs -n1 dirname | sort -u)

    for dir in ${(f)dirs}; do
        echo "Linting directory: $dir"
        golangci-lint run "$dir/"
    done
}
