{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    let
      out = system:
        let
          pkgs = import nixpkgs
            {
              inherit system;
              overlays = [ ];
            };
        in
        {

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              poetry
            ];
          };

          packages.dyndns = with pkgs.poetry2nix; mkPoetryApplication {
            projectDir = ./.;
            preferWheels = true;
          };

          packages.default = self.packages.${system}.dyndns;

        };
    in
    with utils.lib; eachSystem defaultSystems out // {

      nixosModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.j3ff.dyndns;
        in
        {
          options.j3ff.dyndns = {
            enable = mkEnableOption "Enable the Deadeye admin middleware service";

            port = mkOption {
              description = "Port the server listens on.";
              type = types.port;
              default = 5000;
            };

            uploadDir = mkOption {
              description = "Directory used for image uploads.";
              type = types.str;
              default = "/tmp/deadeye";
            };
          };




          config = mkIf cfg.enable
            {
              systemd.services.deadeye-admin = {
                wantedBy = [ "multi-user.target" ];

                environment = {
                  DEADEYE_NT_SERVER = cfg.ntServerAddress;
                  DEADEYE_NT_PORT = "${toString cfg.ntServerPort}";
                  DEADEYE_ADMIN_PORT = "${toString cfg.admin.port}";
                  DEADEYE_NT_WAIT_MS = "500";
                  DEADEYE_UPLOAD_DIR = cfg.admin.uploadDir;
                  FLASK_ENV = "production";
                };

                serviceConfig =
                  let pkg = self.packages.${pkgs.system}.admin;
                  in
                  {
                    Restart = "on-failure";
                    ExecStart = "${pkg}/bin/deadeye-server";
                  };
              };
            };
        };



      nixosConfigurations.container = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.default
          ({ config, pkgs, ... }: {
            # Only allow this to boot as a container
            boot.isContainer = true;
            networking.hostName = "dnydns";

            deadeye.dyndns.enable = true;
          })
        ];
      };
    };
}
