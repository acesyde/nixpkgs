{ lib
, buildGo122Module
, fetchFromGitHub
, fetchNpmDeps
, cacert
, go_1_22
, git
, enumer
, mockgen
, nodejs
, npmHooks
, nix-update-script
, nixosTests
, stdenv
}:

let
  buildGoModule = buildGo122Module;
  go = go_1_22;
in

buildGoModule rec {
  pname = "evcc";
  version = "0.126.2";

  src = fetchFromGitHub {
    owner = "evcc-io";
    repo = "evcc";
    rev = version;
    hash = "sha256-jeOlBHCPn+k+rXADm0hcGqg+7qn8FOJKnCfSwZazRl8=";
  };

  vendorHash = "sha256-jJOxFkoVBT1NrnhntHPa2/irjHD09zKbtNDQoyelJp4=";

  npmDeps = fetchNpmDeps {
    inherit src;
    hash = "sha256-KW2aVK3Ui5sGBcNhTsNXUr9HyHcm0iJxxzBUjrNWrqw=";
  };

  nativeBuildInputs = [
    nodejs
    npmHooks.npmConfigHook
  ];

  overrideModAttrs = _: {
    nativeBuildInputs = [
      enumer
      go
      git
      cacert
      mockgen
    ];

    preBuild = ''
      make assets
    '';
  };

  tags = [
    "release"
    "test"
  ];

  ldflags = [
    "-X github.com/evcc-io/evcc/server.Version=${version}"
    "-X github.com/evcc-io/evcc/server.Commit=${src.rev}"
    "-s"
    "-w"
  ];

  preBuild = ''
    make ui
  '';

  doCheck = !stdenv.isDarwin; # tries to bind to local network, doesn't work in darwin sandbox

  preCheck = ''
    # requires network access
    rm meter/template_test.go
    rm charger/template_test.go
    rm tariff/template_test.go
  '';

  passthru = {
    tests = {
      inherit (nixosTests) evcc;
    };
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "EV Charge Controller";
    homepage = "https://evcc.io";
    changelog = "https://github.com/evcc-io/evcc/releases/tag/${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ hexa ];
  };
}
