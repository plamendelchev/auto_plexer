# auto_plexer
Bash script to easily set up SSH multiplexing. 

## Installation
By default, the script reads its configuration from `~/.config/auto_plexer`. The file must contain the following directives:

- `SSH_CONFIG` - Location of the main SSH configuration file on your system
- `SSH_CONTROL_PATH` - Specify the path to the control socket used for connection sharing
- `SSH_CONTROL_MASTER` - Enables the sharing of multiple sessions over a single network connection
- `SSH_CONTROL_PERSIST` - Specifies that the master connection should remain open in the background after the initial client connection has been closed

For more information about these settings, please see [ssh_config(5)](http://man.openbsd.org/ssh_config.5)

Example configuration:
```
SSH_CONFIG="${HOME}/.ssh/config"
SSH_CONTROL_PATH='/tmp/ssh_multiplex-%h.local.sock'
SSH_CONTROL_MASTER='auto'
SSH_CONTROL_PERSIST='10m'
```

## Usage
Create multiplex configuration
```
auto_plex <hostname>
```
Show SSH multiplex connection status
```
auto_plex -s <hostname>
```
Cancel SSH multiplex connection
```
auto_plex -c <hostname>
```
