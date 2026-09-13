# Ellamma

A lightweight terminal-based AI agent designed to run on resource-constrained Unix-like systems.

Ellamma provides an interactive terminal interface to remote AI models while keeping the local runtime small, simple, and portable. It is built primarily with POSIX shell and command-line utilities, making it suitable for a wide range of devices and environments.

## Overview

Ellamma is designed around a simple architecture:

    Terminal
       |
    ellamma.sh
       |
     HTTPS
       |
    OpenCode Go API
       |
    AI Model

The local device handles the terminal interface, session state, and eventually local tools, while the remote model handles inference.

## Current Features

- Interactive terminal interface
- OpenCode Go API integration
- GPT-5.6 Luna support
- Streaming responses
- Persistent conversation state
- Persistent session identity
- Start a new conversation with `/new`
- Basic command interface
- API key stored outside Git
- Low-resource design
- Modular runtime split across small POSIX shell files

## Project Structure

    ellamma/
    ├── ellamma.sh       entry point
    ├── install.sh       install / uninstall helper
    ├── lib/
    │   ├── common.sh    shared configuration and state
    │   ├── session.sh   session state management
    │   ├── markdown.sh  streaming markdown renderer
    │   ├── api.sh       remote API calls
    │   └── ui.sh        banner, commands, interactive loop
    └── README.md

## Commands

| Command | Description |
|---|---|
| `/help` | Display available commands |
| `/new` | Start a new conversation |
| `/model` | Display the active model |
| `/quit` | Exit Ellamma |

## Requirements

- POSIX-compatible shell
- `curl`
- Working HTTPS connectivity
- OpenCode Go API access
- A Unix-like environment capable of running the shell runtime

Ellamma is designed for any Unix-like environment. Early development was done on a low-end handheld running iOS 6.1.3, but nothing in the runtime depends on that device; it adapts its storage to the host (default `~/.ellamma`).

![](https://raw.githubusercontent.com/recklessradiance/ellamma/refs/heads/main/IMG_0297.jpeg)

## Installation

Ellamma stores its data in a base directory. On most Unix systems this defaults to `~/.ellamma`; the runtime falls back to per-user storage when the default path is not usable, and `ELLAMMA_HOME` overrides it explicitly. Embedded or locked-down deployments may prefer `ELLAMMA_HOME=/var/mobile/.ellamma` (as on the original device).

Run the installer from the project directory:

    ./install.sh

This copies the runtime to `<base>/bin`, installs a `ellamma` launcher on your PATH (default `~/.local/bin`), and prompts for the API key if none is stored yet. The launcher directory can be changed with `ELLAMMA_BIN`.

To remove the installed runtime (keeping the API key and session state):

    ./install.sh uninstall

Manual install:

    mkdir -p ~/.ellamma/sessions
    chmod 700 ~/.ellamma

Store the API key:

    printf '%s\n' 'YOUR_API_KEY' > ~/.ellamma/api_key
    chmod 600 ~/.ellamma/api_key

Place the runtime somewhere convenient, preserving the layout:

    ellamma.sh
    lib/common.sh
    lib/session.sh
    lib/markdown.sh
    lib/api.sh
    lib/ui.sh

Make the entry point executable:

    chmod 755 ellamma.sh

Start Ellamma:

    ./ellamma.sh

## Configuration

The runtime reads the API key from the base directory:

    <base>/api_key

Where `<base>` is `$ELLAMMA_HOME` if set, `~/.ellamma` by default, or the legacy `/var/mobile/.ellamma` when that path is usable.

The key is intentionally excluded from version control.

The current model is configured in the runtime:

`MODEL` in `lib/common.sh` (or via the `ELLAMMA_MODEL` environment variable).

Additional environment overrides supported by `lib/common.sh`:

| Variable | Default | Purpose |
|---|---|---|
| `ELLAMMA_HOME` | `~/.ellamma` (legacy: `/var/mobile/.ellamma`) | Runtime data directory |
| `ELLAMMA_MODEL` | `gpt-5.6-luna` | Model identifier |
| `ELLAMMA_SESSION` | `ellamma-main` | Initial session name |

## Persistent Conversations

Ellamma stores the latest response identifier locally at:

    <base>/sessions/<session>

On the original environment the default session is `ellamma-main`.

When Ellamma starts again, it loads the saved response identifier and continues the previous conversation.

Using:

    /new

creates a new session and clears the previous conversation state.

## Security

The API key should never be committed to Git.

The local key file should use restrictive permissions:

    chmod 600 <base>/api_key

The repository excludes:

    api_key
    sessions/
    logs/
    *.log
    .DS_Store

If an API key is ever exposed publicly, revoke or rotate it immediately.

## Design Principles

### Low Resource Usage

The local client should consume as little CPU, RAM, storage, and network bandwidth as practical.

### No Local Model

Inference is performed remotely. The local device provides the client, state management, and local execution environment.

### Portability

Ellamma avoids unnecessary platform-specific dependencies and is designed around POSIX shell and commonly available command-line tools.

### Small Runtime

The core runtime is a shell script rather than a large application stack.

### Local Control

Conversation state and future local tools remain on the device rather than requiring a separate locally hosted server.

## Architecture

                    +--------------------+
                    |    Remote Model    |
                    |    GPT-5.6 Luna    |
                    +---------^----------+
                              |
                            HTTPS
                              |
                    +---------+----------+
                    |      Ellamma       |
                    |                    |
                    |  Terminal Client   |
                    |  Session Manager   |
                    |  Tool Dispatcher   |
                    +---------+----------+
                              |
                 +------------+------------+
                 |            |            |
              Files         Shell       Internet
              Tools         Tools         Tools

## Development Roadmap

- [x] API connectivity
- [x] Interactive terminal
- [x] Persistent sessions
- [x] Streaming responses
- [ ] Local tool protocol
- [ ] Shell command execution
- [ ] File operations
- [ ] Permission and safety controls
- [ ] Device-aware system context
- [ ] Conversation history
- [ ] Memory
- [ ] Internet tools
- [ ] Calendar integration
- [ ] RSS/news
- [ ] Weather
- [ ] Notifications
- [ ] Platform-specific UX improvements
