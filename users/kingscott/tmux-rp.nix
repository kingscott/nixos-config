# Tmux Rose Pine theme
{ pkgs, ... }:

let
  tmux-rose-pine = pkgs.tmuxPlugins.mkTmuxPlugin
    {
      pluginName = "tmux-rose-pine";
      version = "unstable-...";
      src = pkgs.fetchFromGitHub { 
        owner = "rose-pine";
        repo = "tmux";
        rev = "23233037e48ea5f124b6186f8d232fda03326448";
        sha256 = "";
      };
    };
