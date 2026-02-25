{ ... }:
{
  perSystem =
    { ... }:
    {
      mcp-servers = {
        programs = {
          memory.enable = true;
          sequential-thinking.enable = true;
        };
        flavors.claude-code.enable = true;
      };
    };
}
