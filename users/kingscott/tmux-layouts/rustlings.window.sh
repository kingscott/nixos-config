# Set window root path. Default is `$session_root`.
# Must be called before `new_window`.
window_root "~/rustlings"

# Create new window. If no argument is given, window name will be based on
# layout file name.
new_window "rustlings"

# Split window into panes.
#split_v 20
split_h 30
split_v 50

# Run commands.
run_cmd "cd ~/rustlings; nvim" 0
run_cmd "cd ~/rustlings; rustlings watch" 1
run_cmd "cd ~/rustlings" 2

# Paste text
#send_keys "top"    # paste into active pane
#send_keys "date" 1 # paste into pane 1

# Set active pane.
select_pane 0
