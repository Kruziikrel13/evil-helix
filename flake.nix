{
  description = "A post-modern text editor.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    inherit (nixpkgs) lib;

    forEachSystem = fn: nixpkgs.lib.genAttrs lib.systems.flakeExposed (system: fn system nixpkgs.legacyPackages.${system});
    gitRev = self.rev or self.dirtyRev or null;
  in {
    packages = forEachSystem (system: pkgs: {
      default = self.packages.${system}.evil-helix;
      evil-helix = pkgs.callPackage ./default.nix {inherit gitRev;};
    });

    checks = forEachSystem (system: pkgs: let
      msrvToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      msrvPlatform = pkgs.makeRustPlatform {
        cargo = msrvToolchain;
        rustc = msrvToolchain;
      };
    in {
      evil-helix = self.packages.${system}.evil-helix.override {rustPlatform = msrvPlatform;};
    });

    devShells = forEachSystem (system: pkgs: {
      default = let
        commonRustFlagsEnv = "-C link-arg=-fuse-ld=lld -C target-cpu=native --cfg tokio_unstable";
        platformRustFlagsEnv = lib.optionalString pkgs.stdenv.isLinux "-Clink-arg=-Wl,--no-rosegment";
      in
        pkgs.mkShell {
          inputsFrom = [self.checks.${system}.evil-helix];
          nativeBuildInputs = with pkgs;
            [
              lld
              cargo-flamegraph
              rust-bin.nightly.latest.rust-analyzer
              mdbook
            ]
            ++ (lib.optional (stdenv.hostPlatform.isx86_64 && stdenv.hostPlatform.isLinux) cargo-tarpaulin)
            ++ (lib.optional stdenv.hostPlatform.isLinux lldb);
          shellHook = ''
            export RUST_BACKTRACE="1"
            export RUSTFLAGS="''${RUSTFLAGS:-""} ${commonRustFlagsEnv} ${platformRustFlagsEnv}"
          '';
        };
    });
  };
}
