{ pkgs, inputs, ... }:

{
  # https://github.com/nix-community/home-manager/pull/2408
  #environment.pathsToLink = [ "/share/fish" ];

  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  #programs.fish.enable = true;

  users.users.mitchellh = {
    isNormalUser = true;
    home = "/home/mitchellh";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.bash;
    hashedPassword = "$6$O1u6lRPF8kQYLGzN$roL91UMpozNG7iQT0NnoD8M1OysDoFJNcJ9sePsZ1nyYnCN3y4OyWjZHWT5VoHstjtOry3XntUCf/SvhW2gko/"; # helloworld
    #openssh.authorizedKeys.keys = [
    #  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbTIKIPtrymhvtTvqbU07/e7gyFJqNS4S0xlfrZLOaY mitchellh"
    #];
  };

  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix { inherit inputs; })
  ];
}
