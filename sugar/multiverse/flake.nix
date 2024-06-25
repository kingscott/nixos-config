{
  description = "A very basic Node.js environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let 
      # Supported systems for this environment
      allSystems = [
        "x86_64-linux" # 64-bit linux
        "x86_64-darwin" # 64-bit MacOS
        "aarch64-darwin" # 64-bit MacOS (Apple Silicon)
        "aarch64-linux" # 64-bit linux
      ];

      # Helper to provide system-specific attribute
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });

      in
      {
        # Development environment output
        devShells = forAllSystems ({ pkgs }: {
          default = pkgs.mkShell {
            # Packages we want available in the environment
            packages = with pkgs; [
              nodejs_18
              (yarn.override { nodejs = nodejs_18; })
            ];
          };
        };
      };

}
