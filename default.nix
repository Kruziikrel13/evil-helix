{
  evil-helix,
  rustPlatform,
  gitRev ? null
}: evil-helix.overrideAttrs {
  version = gitRev;
  src = ./.;
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    allowBuiltinFetchGit = true;
  };
  cargoHash = null;
}
