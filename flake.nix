{
  description = "Claude Code Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    claude-module = {
      url = "path:./modules/ai/claude";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, claude-module, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      systems = lib.systems.flakeExposed;
      imports = [ claude-module.flakeModule ];

      perSystem = { config, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Claude configuration
        claude = {
          enable = true;
          dangerouslySkipPermissions = true;
          baseUrl = "https://api.z.ai/api/anthropic";
          models = {
            default = "glm-5";
            opus = "glm-4.7";
            sonnet = "glm-4.7";
            haiku = "glm-4.5-air";
          };
        };

        # MCP servers configuration
        mcp-servers = {
          programs = {
            context7.enable = true;
            memory.enable = true;
            sequential-thinking.enable = true;
            serena.enable = true;
          };
          flavors.claude-code.enable = true;
        };

        devShells.default = config.packages.claude-dev-shell;
      };
    });
}
