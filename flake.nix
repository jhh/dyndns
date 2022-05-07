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
            enable = mkEnableOption "Enable the dyndns service";
          };

          config = mkIf cfg.enable
            {
              systemd.timers.dyndns = {
                description = "Periodic update of home.j3ff.io DNS record";
                wantedBy = [ "multi-user.target" ];

                timerConfig = {
                  OnBootSec = "15min";
                  OnUnitActiveSec = "4h";
                };
              };

              systemd.services.dyndns = {
                description = "Update home.j3ff.io DNS record";

                environment = {
                  DNS_SERVER = "8.8.8.8";
                  DYNDNS_HOST = "home.j3ff.io";
                  AWS_ZONE_ID = "Z2N63DHUXZQTEZ";
                  AWS_ACCESS_KEY_ID = "AKIAIGGOL2YKLGRADUDQ";
                };

                serviceConfig =
                  let pkg = self.packages.${pkgs.system}.dyndns;
                  in
                  {
                    Type = "oneshot";
                    # agenix secret in github:jhh/nixos-configs
                    LoadCredential = "AWS_SECRET_ACCESS_KEY:/run/agenix/aws_secret";
                    ExecStart = "${pkg}/bin/dyndns-cli";

                    DynamicUser = true;
                    NoNewPrivileges = true;
                    ProtectSystem = "strict";
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
            networking.hosts = {
              "3.232.242.170" = [ "api.ipify.org" ];
            };

            j3ff.dyndns.enable = true;
          })
        ];
      };
    };
}
