{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs_20,
}:

buildNpmPackage rec {
  pname = "bmad-method";
  version = "6.0.0-alpha.12";

  src = fetchFromGitHub {
    owner = "bmad-code-org";
    repo = "BMAD-METHOD";
    rev = "9d510fc0751889a521f50fc3575393b09bd90e9b";
    hash = "sha256-QYH6M7qz++CuXYBeh4LWSlB1JByuinhuG3PwwAkt6Zs=";
  };

  npmDepsHash = "sha256-AJaVkMAkNmfGFqOoBjXbWLMJc14KjdWhIsB1RFYKQug=";

  nodejs = nodejs_20;

  dontNpmBuild = true;
  npmPrune = false;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/bmad-method \
      --set NODE_PATH "$out/lib/node_modules/bmad-method" \
      --prefix PATH : ${lib.makeBinPath [ nodejs_20 ]}

    if [ -f "$out/bin/bmad" ]; then
      wrapProgram $out/bin/bmad \
        --set NODE_PATH "$out/lib/node_modules/bmad-method" \
        --prefix PATH : ${lib.makeBinPath [ nodejs_20 ]}
    fi
  '';

  meta = {
    description = "Universal AI Agent Framework for AI-assisted development";
    homepage = "https://github.com/bmadcode/BMAD-METHOD";
    license = lib.licenses.mit;
    mainProgram = "bmad-method";
    platforms = lib.platforms.all;
  };
}
