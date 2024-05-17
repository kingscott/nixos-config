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
	  pkgs.bash
    pkgs.bat
    pkgs.fd
    pkgs.fzf
    pkgs.gh
    pkgs.htop
    pkgs.jq
    pkgs.pinentry-gnome
    pkgs.ripgrep
    pkgs.tmuxifier
    pkgs.tree
    pkgs.unzip
    pkgs.watch
    pkgs.zip

    # Needed to add to get login working
    pkgs.plymouth
    
    # Multiverse dependencies
    pkgs.bazelisk
    pkgs.go
    pkgs.gopls
	
    # Node is required for Copilot.vim
    pkgs.nodejs
  ] ++ (lib.optionals isDarwin [
	  # TODO REMOVE
    # This is automatically setup on Linux
    # pkgs.cachix
    # pkgs.tailscale
  ]) ++ (lib.optionals (isLinux && !isWSL) [
    pkgs.firefox
    pkgs.rofi
    pkgs.valgrind
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
  home.file.".tmux-layouts".source = ./tmux-layouts;

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
    initExtra = builtins.readFile ./bashrc;

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
      grb = "git rebase";
      tma = "tmux a";
      tmr = "tmuxifier";
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

  programs.git = {
    enable = true;
    userName = "Scott King";
    userEmail = "scott.king@sugarcrm.com";
    signing = {
      key = "24B09299299348FB";
      signByDefault = true;
    };
    aliases = {
      cleanup = "!git branch --merged | grep  -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d";
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
      ci = "commit";
      ch = "checkout";
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      credential.helper = "store"; # want to make this more secure
      github.user = "kingscott-sugarcrm";
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
      vimPlugins.alpha-nvim
      vimPlugins.cmp-nvim-lsp
      vimPlugins.gitsigns-nvim
      vimPlugins.harpoon
      vimPlugins.lsp-zero-nvim
      vimPlugins.luasnip
      vimPlugins.mason-nvim
      vimPlugins.mason-lspconfig-nvim
      vimPlugins.nvim-cmp
      vimPlugins.nvim-lspconfig
      #vimPlugins.nvim-treesitter
      vimPlugins.plenary-nvim
      vimPlugins.rose-pine
      vimPlugins.telescope-nvim
      vimPlugins.undotree
      vimPlugins.vim-fugitive

      customVim.nvim-treesitter
      customVim.vim-copilot
      customVim.vim-devicons
    ];
	
    extraConfig = (import ./vim-config.nix) { inherit sources; };
  };

  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    shortcut = "l";
    secureSocket = false;

    extraConfig = ''
    # Make reloading the config easy
    unbind r
    bind r source-file ~/.config/tmux/tmux.conf

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

    set -g set-clipboard on

    # Scott King's theming for tmux
    set -g @rose_pine_variant 'main' # Options are 'main', 'moon' or 'dawn'
    set -g @rose_pine_host 'on' # Enables hostname in the status bar
    set -g @rose_pine_date_time "" # It accepts the date UNIX command format (man date for info)
    set -g @rose_pine_user 'on' # Turn on the username component in the statusbar
    set -g @rose_pine_directory 'on' # Turn on the current folder component in the status bar
    set -g @rose_pine_bar_bg_disable 'on' # Disables background color, for transparent terminal emulators
    # If @rose_pine_bar_bg_disable is set to 'on', uses the provided value to set the background color
    # It can be any of the on tmux (named colors, 256-color set, `default` or hex colors)
    # See more on http://man.openbsd.org/OpenBSD-current/man1/tmux.1#STYLES
    set -g @rose_pine_bar_bg_disabled_color_option 'default'
    # set -g @rose_pine_only_windows 'on' # Leaves only the window module, for max focus and space
    set -g @rose_pine_disable_active_window_menu "" # Disables the menu that shows the active window on the left

    set -g @rose_pine_default_window_behavior 'on' # Forces tmux default window list behaviour
    set -g @rose_pine_show_current_program 'on' # Forces tmux to show the current running program as window name
    set -g @rose_pine_show_pane_directory 'on' # Forces tmux to show the current directory as window name
    # Previously set -g @rose_pine_window_tabs_enabled

    # Example values for these can be:
    set -g @rose_pine_left_separator ' > ' # The strings to use as separators are 1-space padded
    set -g @rose_pine_right_separator ' < ' # Accepts both normal chars & nerdfont icons
    set -g @rose_pine_field_separator ' | ' # Again, 1-space padding, it updates with prefix + I
    set -g @rose_pine_window_separator ' - ' # Replaces the default `:` between the window number and name

    # These are not padded
    set -g @rose_pine_session_icon ' ' # Changes the default icon to the left of the session name
    set -g @rose_pine_current_window_icon '' # Changes the default icon to the left of the active window name
    set -g @rose_pine_folder_icon '' # Changes the default icon to the left of the current directory folder
    set -g @rose_pine_username_icon '' # Changes the default icon to the right of the hostname
    set -g @rose_pine_hostname_icon '󰒋' # Changes the default icon to the right of the hostname
    set -g @rose_pine_date_time_icon '󰃰' # Changes the default icon to the right of the date module
    set -g @rose_pine_window_status_separator "  " # Changes the default icon that appears between window names

    bind -n C-k send-keys "clear"\; send-keys "Enter"

    run-shell ${sources.tmux-rose-pine}/rose-pine.tmux
    '';
  };

  programs.alacritty = {
    enable = !isWSL;

    settings = {
      env.TERM = "xterm-256color";

      font = {
        normal = {
          family = "FiraCode Nerd Font Mono";
          style = "Retina";
        };
        bold = { 
          style = "Bold";
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
    pinentryFlavor = "gnome3";

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

  # TODO REMOVE
  #xresources.extraConfig = builtins.readFile ./Xresources;

  # kingscott: Not really sure what this does. 
  # Make cursor not tiny on HiDPI screens
  home.pointerCursor = lib.mkIf (isLinux && !isWSL) {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
