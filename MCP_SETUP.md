# MCP Server Configuration for Flutter Development

This guide explains how to set up Model Context Protocol (MCP) servers for Flutter development in Cursor.

## Quick Setup

1. **Open Cursor Settings**
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type: `Preferences: Open User Settings (JSON)`

2. **Add the Configuration**
   - Copy the contents from `.cursor-mcp-config.json`
   - Paste into your Cursor settings JSON file
   - Replace placeholder values (API keys, tokens, paths) with your actual values

3. **Restart Cursor**
   - Close and reopen Cursor for changes to take effect

## Available MCP Servers

### 1. Filesystem Server ✅ (Recommended)
- **Purpose**: Browse and read files in your Flutter project
- **Setup**: No API keys needed, just update the path
- **Use Case**: Explore project structure, read code files

### 2. GitHub Server
- **Purpose**: Access Flutter/Dart repositories, search for examples
- **Setup**: 
  1. Go to GitHub → Settings → Developer settings → Personal access tokens
  2. Create a token with `repo` scope
  3. Replace `your-github-token-here` in config
- **Use Case**: Search Flutter packages, access official Flutter repo

### 3. Brave Search Server
- **Purpose**: Search for Flutter packages, documentation, solutions
- **Setup**:
  1. Get API key from https://brave.com/search/api/
  2. Replace `your-brave-api-key-here` in config
- **Use Case**: Find Flutter packages on pub.dev, search Stack Overflow

### 4. Puppeteer Server ✅ (Recommended for Web)
- **Purpose**: Test Flutter web builds, automate browser interactions
- **Setup**: No API keys needed
- **Use Case**: Test your Flutter web app, take screenshots, automate testing

### 5. GitLab Server (Optional)
- **Purpose**: Access GitLab repositories
- **Setup**: Create GitLab personal access token
- **Use Case**: If you use GitLab instead of GitHub

### 6. PostgreSQL Server (Optional)
- **Purpose**: Query PostgreSQL databases
- **Setup**: Update connection string with your database credentials
- **Use Case**: If your Flutter app connects to a PostgreSQL backend

### 7. Firecrawl Server (Optional)
- **Purpose**: Scrape Flutter documentation websites
- **Setup**: Get API key from https://firecrawl.dev
- **Use Case**: Extract content from Flutter docs, pub.dev package pages

### 8. SQLite Server (Optional)
- **Purpose**: Query SQLite databases
- **Setup**: Update path to your SQLite database file
- **Use Case**: Debug Flutter apps using sqflite package

## Minimal Setup (Just the Essentials)

If you want to start with just the basics, use this minimal config:

```json
{
  "mcp.servers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/admir/Documents/Projects/next_set"
      ]
    },
    "puppeteer": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-puppeteer"
      ]
    }
  }
}
```

## Browser Servers (Already Available)

These are already configured in Cursor:
- `cursor-browser-extension` - Test Flutter web builds
- `cursor-ide-browser` - Navigate and interact with web pages

## Testing Your Setup

After configuration, test by asking the AI assistant:
- "List available MCP resources"
- "Browse my Flutter project files"
- "Search for Flutter state management solutions"
- "Test my Flutter web app using the browser"

## Troubleshooting

### Servers not appearing?
- Make sure you've restarted Cursor after adding the config
- Check that Node.js and npm are installed: `node --version` and `npm --version`
- Verify the JSON syntax is correct (no trailing commas)

### API Key Issues?
- Double-check your API keys are correct
- Ensure tokens have the right permissions/scopes
- Some servers work without API keys (filesystem, puppeteer)

### Path Issues?
- Use absolute paths (starting with `/`)
- Ensure the paths exist and are accessible
- On Windows, use forward slashes or escaped backslashes

## Additional Resources

- MCP Documentation: https://modelcontextprotocol.io
- Available Servers: https://mcp.so
- Flutter Documentation: https://docs.flutter.dev
