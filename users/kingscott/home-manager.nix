{ isWSL, inputs, ... }:

{ config, lib, pkgs, ... }:

let
  sources = import ../../nix/sources.nix;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = (pkgs.writeShellScriptBin "manpager" (if isDarwin then ''
    sh -c 'col -bx | bat -l man -p'
    '' else ''
    cat "$1" | col -bx | bat --language man --style plain
  ''));

  tmux-rose-pine = pkgs.tmuxPlugins.mkTmuxPlugin
    {
      pluginName = "tmux-rose-pine";
      version = "unstable-...";
      src = pkgs.fetchFromGitHub { 
        owner = "rose-pine";
        repo = "tmux";
        rev = "23233037e48ea5f124b6186f8d232fda03326448";
        sha256 = "sha256-0ccJVQIIOpHdr3xMIBC1wbgsARCNpmN+xMYVO6eu/SI=";
      };
    };
in {
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home.stateVersion = "18.09";

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    pkgs.asciinema
    pkgs.bat
    pkgs.fd
    pkgs.fzf
    pkgs.gh
    pkgs.htop
    pkgs.jq
    pkgs.ripgrep
    pkgs.tree
    pkgs.watch

    pkgs.gopls
    #pkgs.zigpkgs."0.12.0"

    # Node is required for Copilot.vim
    pkgs.nodejs

	# Needed to add to get login working
	pkgs.plymouth
  ] ++ (lib.optionals isDarwin [
	# TODO REMOVE
    # This is automatically setup on Linux
    # pkgs.cachix
    # pkgs.tailscale
  ]) ++ (lib.optionals (isLinux && !isWSL) [
	# TODO REMOVE
    # pkgs.chromium

    pkgs.firefox
    pkgs.rofi
    pkgs.valgrind
    #pkgs.zathura
  ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "${manpager}/bin/manpager";
  };

  home.file.".gdbinit".source = ./gdbinit;
  home.file.".inputrc".source = ./inputrc;

  xdg.configFile = {
    "i3/config".text = builtins.readFile ./i3;
    "rofi/config.rasi".text = builtins.readFile ./rofi;

    # tree-sitter parsers
    "nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
    "nvim/queries/proto/folds.scm".source =
      "${sources.tree-sitter-proto}/queries/folds.scm";
    "nvim/queries/proto/highlights.scm".source =
      "${sources.tree-sitter-proto}/queries/highlights.scm";
    "nvim/queries/proto/textobjects.scm".source =
      ./textobjects.scm;
  }; 

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.gpg.enable = !isDarwin;

  programs.bash = {
    enable = true;
    shellOptions = [];
    historyControl = [ "ignoredups" "ignorespace" ];
    #initExtra = builtins.readFile ./bashrc;

    shellAliases = {
      ga = "git add";
      gci = "git commit";
      gco = "git checkout";
      gcp = "git cherry-pick";
      gdiff = "git diff";
      gl = "git prettylog";
      gp = "git push";
      gs = "git status";
      gt = "git tag";
    };
  };

  # TODO SETUP DIRENV
  #programs.direnv= {
  #  enable = true;

  #  config = {
  #    whitelist = {
  #      prefix= [
  #        "$HOME/code/go/src/github.com/hashicorp"
  #        "$HOME/code/go/src/github.com/mitchellh"
  #      ];

  #      exact = ["$HOME/.envrc"];
  #    };
  #  };
  #};

  # TODO REMOVE
  #programs.fish = {
  #  enable = true;
  #  interactiveShellInit = lib.strings.concatStrings (lib.strings.intersperse "\n" ([
  #    "source ${sources.theme-bobthefish}/functions/fish_prompt.fish"
  #    "source ${sources.theme-bobthefish}/functions/fish_right_prompt.fish"
  #    "source ${sources.theme-bobthefish}/functions/fish_title.fish"
  #    (builtins.readFile ./config.fish)
  #    "set -g SHELL ${pkgs.fish}/bin/fish"
  #  ]));

  #  shellAliases = {
  #    ga = "git add";
  #    gc = "git commit";
  #    gco = "git checkout";
  #    gcp = "git cherry-pick";
  #    gdiff = "git diff";
  #    gl = "git prettylog";
  #    gp = "git push";
  #    gs = "git status";
  #    gt = "git tag";
  #  } // (if isLinux then {
  #    # Two decades of using a Mac has made this such a strong memory
  #    # that I'm just going to keep it consistent.
  #    pbcopy = "xclip";
  #    pbpaste = "xclip -o";
  #  } else {});

  #  plugins = map (n: {
  #    name = n;
  #    src  = sources.${n};
  #  }) [
  #    "fish-fzf"
  #    "fish-foreign-env"
  #    "theme-bobthefish"
  #  ];
  #};

  programs.git = {
    enable = true;
    userName = "Scott King";
    userEmail = "scott.king@sugarcrm.com";
    signing = {
      # TODO SETUP 
      key = "523D5DC389D273BC";
      signByDefault = true;
    };
    aliases = {
      cleanup = "!git branch --merged | grep  -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d";
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      credential.helper = "store"; # want to make this more secure
      github.user = "kingscott";
      push.default = "tracking";
      init.defaultBranch = "main";
    };
  };

  # TODO SETUP
  programs.go = {
    enable = true;
    goPath = "code/go";
    goPrivate = [ "github.com/mitchellh" "github.com/hashicorp" "rfc822.mx" ];
  };

  programs.neovim = {
    enable = true;

    plugins = with pkgs; [
      vimPlugins.harpoon
      vimPlugins.rose-pine
    ];

    extraConfig = "colorscheme rose-pine";

    extraLuaConfig = ''
      vim.g.mapleader = " "
      vim.keymap.set("n", ";", ":")
      vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

      vim.opt.guicursor = ""
      vim.opt.nu = true
      vim.opt.tabstop = 4
      vim.opt.softtabstop = 4
      vim.opt.shiftwidth = 4
      vim.opt.smartindent = true
      vim.opt.wrap = false
      vim.opt.swapfile = false
      vim.opt.backup = false
      vim.opt.writebackup = false

      -- Harpoon config
      local mark = require("harpoon.mark")
      local ui = require("harpoon.ui")

      vim.keymap.set("n", "<leader>a", mark.add_file)
      vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

      vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
      vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)  
      vim.keymap.set("n", "<C-n>", function() ui.nav_file(3) end)  
      vim.keymap.set("n", "<C-s>", function() ui.nav_file(4) end)  
    '';
  };

  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    shortcut = "l";
    secureSocket = false;

    plugins = with pkgs; [
      {
        plugin = tmux-rose-pine;
        extraConfig = "";
      }
    ];

    extraConfig = ''
      # Make reloading the config easy
      unbind r
      bind r source-file ~/.tmux.conf

      # Make sure TMUX doesn't hijack our nvim colours (sync colours between both systems)
      set -g default-terminal "xterm-256color"
      set-option -ga terminal-overrides ",xterm-256color:Tc"

      # Make Ctrl+s the prefix key
      set -g prefix C-s

      # Allow panes to be resized with mouse
      set -g mouse on

      # Move status to top
      set -g status-position top

      # Create vim-like keybindings for moving around
      bind-key h select-pane -L 
      bind-key j select-pane -D 
      bind-key k select-pane -U 
      bind-key l select-pane -R 

      # Mitchell H's configs for tmux 
      set -g @dracula-show-battery false
      set -g @dracula-show-network false
      set -g @dracula-show-weather false

      bind -n C-k send-keys "clear"\; send-keys "Enter"

      run-shell ${sources.tmux-pain-control}/pain_control.tmux
      run-shell ${sources.tmux-dracula}/dracula.tmux
    '';
  };

  programs.alacritty = {
    enable = !isWSL;

    settings = {
      # TODO Update theme
      
      env.TERM = "xterm-256color";

      font = {
        normal = {
          family = "FiraCode Nerd Font";
          style = "Retina";
        };
        bold = { 
          style = "bold";
        };
        size = 16;
      };

      colors = {
        primary = {
          background = "0x191724";
          foreground = "0xe0def4";
        };
        cursor = {
          text = "0xe0def4";
          cursor = "0x524f67";
        };
        vi_mode_cursor = {
          text = "0xe0def4";
          cursor = "0x524f67";
        };
        selection = {
          text = "0xe0def4";
          background = "0x403d52";
        };
        normal = {
          black = "0x26233a";
          red = "0xeb6f92";
          green = "0x31748f";
          yellow = "0xf6c177";
          blue = "0x9ccfd8";
          magenta = "0xc4a7e7";
          cyan = "0xebbcba";
          white = "0xe0def4";
        };
        bright = {
          black = "0x6e6a86";
          red = "0xeb6f92";
          green = "0x31748f";
          yellow = "0xf6c177";
          blue = "0x9ccfd8";
          magenta = "0xc4a7e7";
          cyan = "0xebbcba";
          white = "0xe0def4";
        };
        hints = {
          start = {
            foreground = "#908caa";
            background = "#1f1d2e";
          };
          end = {
            foreground = "#6e6a86";
            background = "#1f1d2e";
          };
        };
      };

      # TODO REMOVE
      #key_bindings = [
      #  { key = "K"; mods = "Command"; chars = "ClearHistory"; }
      #  { key = "V"; mods = "Command"; action = "Paste"; }
      #  { key = "C"; mods = "Command"; action = "Copy"; }
      #  { key = "Key0"; mods = "Command"; action = "ResetFontSize"; }
      #  { key = "Equals"; mods = "Command"; action = "IncreaseFontSize"; }
      #  { key = "Subtract"; mods = "Command"; action = "DecreaseFontSize"; }
      #];
    };
  };

  # TODO REMOVE
  #programs.kitty = {
  #  enable = !isWSL;
  #  extraConfig = builtins.readFile ./kitty;
  #};

  programs.i3status = {
    enable = isLinux && !isWSL;

    general = {
      colors = true;
      color_good = "#8C9440";
      color_bad = "#A54242";
      color_degraded = "#DE935F";
    };

    modules = {
      ipv6.enable = false;
      "wireless _first_".enable = false;
      "battery all".enable = false;
    };
  };

  # TODO REMOVE
  #programs.neovim = {
  #  enable = true;
  #  package = pkgs.neovim-nightly;

  #  withPython3 = true;

  #  plugins = with pkgs; [
  #    customVim.vim-copilot
  #    customVim.vim-cue
  #    customVim.vim-fish
  #    customVim.vim-fugitive
  #    customVim.vim-glsl
  #    customVim.vim-misc
  #    customVim.vim-pgsql
  #    customVim.vim-tla
  #    customVim.vim-zig
  #    customVim.pigeon
  #    customVim.AfterColors

  #    customVim.vim-nord
  #    customVim.nvim-cinnamon
  #    customVim.nvim-comment
  #    customVim.nvim-conform
  #    customVim.nvim-lspconfig
  #    customVim.nvim-plenary # required for telescope
  #    customVim.nvim-telescope
  #    customVim.nvim-treesitter
  #    customVim.nvim-treesitter-playground
  #    customVim.nvim-treesitter-textobjects

  #    # TODO REMOVE
  #    #vimPlugins.vim-airline
  #    #vimPlugins.vim-airline-themes
  #    #vimPlugins.vim-eunuch
  #    #vimPlugins.vim-gitgutter

  #    vimPlugins.vim-markdown
  #    vimPlugins.vim-nix
  #    vimPlugins.typescript-vim
  #    vimPlugins.nvim-treesitter-parsers.elixir
  #  ] ++ (lib.optionals (!isWSL) [
  #    # This is causing a segfaulting while building our installer
  #    # for WSL so just disable it for now. This is a pretty
  #    # unimportant plugin anyway.
  #    customVim.vim-devicons
  #  ]);

  #  # TODO MOVE lua config here
  #  #extraConfig = (import ./vim-config.nix) { inherit sources; };
  #};

  services.gpg-agent = {
    enable = isLinux;
    pinentryFlavor = "tty";

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

<<<<<<< HEAD
  #xresources.extraConfig = builtins.readFile ./Xresources;
=======
  xresources.extraConfig = builtins.readFile ./Xresources;
>>>>>>> d3f2d02 (Initial commit for sugardev)

  # kingscott: Not really sure what this does. 
  # Make cursor not tiny on HiDPI screens
  home.pointerCursor = lib.mkIf (isLinux && !isWSL) {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
