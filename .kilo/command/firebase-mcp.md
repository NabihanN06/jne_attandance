---
name: firebase-mcp
description: Start Firebase MCP server for interacting with Firebase services
usage: kilocode firebase-mcp [--project <projectId>] [--port <port>]
---

Start the Firebase Model Context Protocol (MCP) server to enable AI assistants to interact with Firebase projects. This server provides tools for reading/writing Firestore, managing authentication, deployments, and more.

## Options

- `--project`, `-p`: Firebase project ID (default: from .firebaserc or firebase.json)
- `--port`, `-P`: Port for MCP server (default: 3000)
- `--debug`: Enable debug logging

## Examples

```bash
# Start MCP server using default project from .firebaserc
kilocode firebase-mcp

# Specify project and port
kilocode firebase-mcp --project admin-absensi-jne-mtp --port 3001
```

## What it does

The Firebase MCP server exposes Firebase Tools capabilities including:
- Firestore: read/write documents, collections, queries
- Auth: manage users
- Hosting: deploy, rollback, view channels
- Functions: list, deploy, logs
- Storage: file operations
- Emulators: control emulator suite

## Prerequisites

1. Firebase CLI installed (included in .kilo/node_modules)
2. Authenticated: `firebase login` (already done in workspace)
3. Project configured: .firebaserc or firebase.json present

## Technical Details

The command runs `npx firebase-tools mcp` with the appropriate project context. The MCP server uses stdio transport for communication with the AI assistant.
