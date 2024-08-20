{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  packages = [ pkgs.git ];

                  languages = {
                    erlang.enable = true;
                    elixir.enable = true;
                  };

                  services.postgres = {
                    enable = true;
                    package = pkgs.postgresql;
                    listen_addresses = "127.0.0.1";
                    initialScript = "CREATE ROLE hamarr SUPERUSER LOGIN PASSWORD 'password321';";
                    initialDatabases = [{ name = "hamarr_db"; }];
                  };

                  devcontainer.enable = true;
                  difftastic.enable = true;
                  dotenv.enable = true;
                }
              ];
            };
          });
    };
}
