# Configure GitHub Copilot MCP for Supabase

Add the MCP server and authenticate locally so the Copilot CLI can use Supabase MCP features.

1) Add the MCP server (CLI):

```powershell
copilot mcp add --transport http supabase "https://mcp.supabase.com/mcp?project_ref=hqmtzqgqhqdgzzkcwraf&features=docs%2Caccount%2Cdatabase%2Cdebugging%2Cdevelopment%2Cfunctions%2Cbranching"
```

2) Example config file (place at ~/.copilot/mcp-config.json or use with `copilot -i /mcp`):

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=hqmtzqgqhqdgzzkcwraf&features=docs%2Caccount%2Cdatabase%2Cdebugging%2Cdevelopment%2Cfunctions%2Cbranching"
    }
  }
}
```

3) Start an interactive Copilot session using the MCP transport:

```powershell
copilot -i /mcp
```

Optional: Install Supabase Agent Skills to improve Copilot's Supabase support:

```bash
npx skills add supabase/agent-skills
```
