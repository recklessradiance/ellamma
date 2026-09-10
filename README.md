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
- Persistent conversation state
- Persistent session identity
- Start a new conversation with `/new`
- Basic command interface
- API key stored outside Git
- Low-resource design
- Single canonical runtime script

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

Ellamma was initially developed and tested on an iPhone 4S running iOS 6.1.3, but the project is not tied to that device.

![](https://raw.githubusercontent.com/recklessradiance/ellamma/refs/heads/main/IMG_0297.jpeg)

## Installation

Create the Ellamma directory:

    mkdir -p /var/mobile/.ellamma/sessions
    chmod 700 /var/mobile/.ellamma

Store the API key:

    printf '%s\n' 'YOUR_API_KEY' > /var/mobile/.ellamma/api_key
    chmod 600 /var/mobile/.ellamma/api_key

Place the runtime at:

    /var/mobile/.ellamma/ellamma.sh

Make it executable:

    chmod 755 /var/mobile/.ellamma/ellamma.sh

Start Ellamma:

    cd /var/mobile/.ellamma
    ./ellamma.sh

For other Unix-like systems, adapt the storage paths as needed.

## Configuration

The runtime reads the API key from:

    /var/mobile/.ellamma/api_key

The key is intentionally excluded from version control.

The current model is configured in the runtime:

    MODEL="gpt-5.6-luna"

## Persistent Conversations

Ellamma stores the latest response identifier locally.

On the original environment:

    /var/mobile/.ellamma/sessions/ellamma-main

When Ellamma starts again, it loads the saved response identifier and continues the previous conversation.

Using:

    /new

creates a new session and clears the previous conversation state.

## Security

The API key should never be committed to Git.

The local key file should use restrictive permissions:

    chmod 600 /var/mobile/.ellamma/api_key

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
- [ ] Streaming responses
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
