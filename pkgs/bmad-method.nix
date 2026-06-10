{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs_22,
}:

buildNpmPackage rec {
  pname = "bmad-method";
  version = "6.8.0";

  src = fetchFromGitHub {
    owner = "bmad-code-org";
    repo = "BMAD-METHOD";
    rev = "3bcd6c3cce6e381b759e23185b099081496567a5";
    hash = "sha256-lEMUaIFHuFvcqTEMIH95pB4Bmnuq6N5J8LCHHiRnv1A=";
  };

  npmDepsHash = "sha256-VM2ICB1LxHh2l5iIeKzMOyWm1qoAKMPfxCUMGTBtX/g=";

  nodejs = nodejs_22;

  dontNpmBuild = true;
  npmPrune = false;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/bmad-method \
      --set NODE_PATH "$out/lib/node_modules/bmad-method" \
      --prefix PATH : ${lib.makeBinPath [ nodejs_22 ]}

    if [ -f "$out/bin/bmad" ]; then
      wrapProgram $out/bin/bmad \
        --set NODE_PATH "$out/lib/node_modules/bmad-method" \
        --prefix PATH : ${lib.makeBinPath [ nodejs_22 ]}
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
