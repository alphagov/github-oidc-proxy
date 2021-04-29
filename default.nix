argsOuter@{...}:
let
  # specifying args defaults in this slightly non-standard way to allow us to include the default values in `args`
  args = rec {
    pkgs = import <nixpkgs> {};
    localOverridesPath = ./local.nix;
  } // argsOuter;
in (with args; {

  githubOIDCProxyEnv = (pkgs.stdenv.mkDerivation rec {
    name = "github-oidc-proxy-env";
    shortName = "gh-oidc-prx";
    buildInputs = [
      pkgs.gitFull
      pkgs.cacert
      pkgs.nodejs-14_x
      pkgs.openssl
      pkgs.openssh
      pkgs.terraform_0_13
    ];

    LD_LIBRARY_PATH = "${pkgs.stdenv.lib.makeLibraryPath buildInputs}";
    LANG="en_GB.UTF-8";

    shellHook = ''
      export PS1="\[\e[0;36m\](nix-shell\[\e[0m\]:\[\e[0;36m\]${shortName})\[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[0m\]\[\e[0;36m\]\w\[\e[0m\]\$ "
    '';
  }).overrideAttrs (if builtins.pathExists localOverridesPath then (import localOverridesPath args) else (x: x));
})
