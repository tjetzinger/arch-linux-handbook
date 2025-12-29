# 09 - Development Tools

Language managers and build tools.

## Python

### Conda

Package and environment manager.

**Config:** `~/.condarc`

```yaml
channels:
  - defaults
```

### Commands

```bash
# List environments
conda env list

# Create environment
conda create -n myenv python=3.11

# Activate
conda activate myenv

# Deactivate
conda deactivate

# Install package
conda install numpy pandas

# Export environment
conda env export > environment.yml

# Create from file
conda env create -f environment.yml
```

### Virtual Environments (venv)

Standard Python venv:

```bash
# Create venv
python -m venv venv

# Activate
source venv/bin/activate

# Deactivate
deactivate

# Install requirements
pip install -r requirements.txt
```

### pip

```bash
pip install package
pip install -r requirements.txt
pip freeze > requirements.txt
pip list
pip show package
```

## Node.js

### NVM (Node Version Manager)

Initialized in shell config:

```bash
source /usr/share/nvm/init-nvm.sh
```

### Commands

```bash
# List installed versions
nvm ls

# List available versions
nvm ls-remote

# Install version
nvm install 22
nvm install --lts

# Use version
nvm use 22
nvm use --lts

# Set default
nvm alias default 22

# Current version
node --version
npm --version
```

### Current Version

Node.js v22.21.1 installed via NVM.

### npm

```bash
# Install package
npm install package
npm install -g package    # Global

# Install dependencies
npm install
npm ci                    # Clean install

# Run scripts
npm run build
npm run dev
npm test

# Update
npm update
npm outdated
```

### pnpm/yarn

Alternative package managers (install if needed):

```bash
# pnpm
npm install -g pnpm
pnpm install
pnpm add package

# yarn
npm install -g yarn
yarn install
yarn add package
```

## Rust

### Cargo

Rust package manager and build tool.

```bash
# Check version
cargo --version
rustc --version

# New project
cargo new project_name
cargo init                # In existing dir

# Build
cargo build
cargo build --release

# Run
cargo run

# Test
cargo test

# Check (fast compile check)
cargo check

# Add dependency
cargo add package

# Update dependencies
cargo update
```

### rustup

Rust toolchain manager:

```bash
# Update Rust
rustup update

# Add component
rustup component add clippy
rustup component add rustfmt

# Switch toolchain
rustup default stable
rustup default nightly
```

## Go

### Installation

```bash
which go
# /usr/bin/go

go version
```

### Commands

```bash
# Initialize module
go mod init module-name

# Download dependencies
go mod download
go mod tidy

# Build
go build
go build -o binary-name

# Run
go run main.go

# Test
go test ./...

# Format
go fmt ./...

# Vet (static analysis)
go vet ./...
```

### Go Environment

```bash
go env GOPATH
go env GOROOT
```

## Build Tools

### Make

```bash
make              # Default target
make target       # Specific target
make clean        # Clean build
make -j4          # Parallel build
```

### CMake

```bash
# Configure
cmake -B build

# Build
cmake --build build

# Install
cmake --install build
```

### ccache

Compiler cache for faster rebuilds:

```bash
# In PATH (from zshrc)
export PATH="/usr/lib/ccache/bin/:$PATH"

# Stats
ccache -s

# Clear cache
ccache -C
```

## Docker

Docker CLI available for containerized development:

```bash
# Build image
docker build -t image:tag .

# Run container
docker run -it image:tag

# List containers
docker ps -a

# Docker Compose
docker compose up -d
docker compose down
```

See [../docker/](../docker/) for full Docker documentation.

## Language Servers

LSP servers for editor integration (managed by Mason in Neovim):

| Language | Server |
|----------|--------|
| Python | pyright |
| TypeScript/JS | ts_ls |
| Rust | rust_analyzer |
| Go | gopls |
| C/C++ | clangd |

## Quick Reference

```bash
# Python
conda activate env        # Activate conda env
source venv/bin/activate  # Activate venv
pip install package       # Install package

# Node.js
nvm use 22               # Switch Node version
npm install              # Install dependencies
npm run dev              # Run dev script

# Rust
cargo build              # Build project
cargo run                # Run project
cargo test               # Run tests

# Go
go build                 # Build
go run main.go           # Run
go test ./...            # Test

# Docker
docker compose up -d     # Start services
```

## Related

- [03-NEOVIM](./03-NEOVIM.md) - LSP configuration
- [08-GIT-SSH](./08-GIT-SSH.md) - Version control
- [../docker/](../docker/) - Docker infrastructure
