# Set window root path. Default is `$session_root`.
# Must be called before `new_window`.
window_root "~/devdocs"

# Create new window. If no argument is given, window name will be based on
# layout file name.
new_window "devdocs"

# Split window into panes.
#split_v 20
#split_h 30

# Run commands.
run_cmd "cd ~/devdocs; nvim"

# Paste text
#send_keys "top"    # paste into active pane
#send_keys "date" 1 # paste into pane 1

# Set active pane.
#select_pane 0
