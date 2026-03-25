{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs_20,
}:

buildNpmPackage rec {
  pname = "bmad-method";
  version = "6.2.1";

  src = fetchFromGitHub {
    owner = "bmad-code-org";
    repo = "BMAD-METHOD";
    rev = "fce9d6c0c8ad893f88af9dea69cfcbc8f9f79896";
    hash = "sha256-I2Ko58t5/Zqoy/w4aTE4wat5boOy0BwURq0J0ZPm+q8=";
  };

  npmDepsHash = "sha256-KEmCJMH2aWepRgp07Vg7OZKuP2mrDxlJ5PPLwTdI9NY=";

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
