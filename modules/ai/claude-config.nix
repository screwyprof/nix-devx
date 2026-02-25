{ ... }:
{
  perSystem =
    { ... }:
    {
      ai.claude = {
        enable = true;
        dangerouslySkipPermissions = true;
        baseUrl = "https://api.z.ai";
        models = {
          default = "glm-5";
          opus = "glm-4.7";
          sonnet = "glm-4.7";
          haiku = "glm-4.5-air";
        };
      };
    };
}
