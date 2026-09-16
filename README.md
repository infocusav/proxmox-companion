# proxmox-companion
Shell script to install [Bitfocus Companion](https://bitfocus.io/companion) in a Proxmox LXC container.

The script will:
- Detect a storage that supports container root filesystems (preferring `local-lvm`, then `local`), prompting if more than one is available
- Detect a storage that supports templates, and reuse an existing Debian template or automatically download one matching your host's architecture (prefers Debian 12; override with `PREFERRED_DEBIAN=13`)
- Create and start the container, wait for it to boot, and install Companion inside it
- Enable Companion to start on boot

No manual template download is required.

## Usage

Run the following command within the Proxmox `>_ Shell` and follow the prompts for container number, name, password (entered twice to confirm), VLAN tag (optional), and network configuration (DHCP or a static IP/gateway in CIDR notation):

<pre>
<code>bash -c "$(wget -qLO - https://raw.githubusercontent.com/infocusav/proxmox-companion/main/install-companion.sh)"
</code>
</pre>

### Example session

<pre>
<code>Enter container number (e.g., 100): 105
Enter container name: companion-01
Enter password for the container: ********
Confirm password for the container: ********
Enter VLAN tag (leave blank for none): 20
Use DHCP for networking? (y/n): n
Enter the container IP address with CIDR subnet mask (e.g., 10.0.0.50/24): 10.0.20.50/24
Enter the gateway IP address (e.g., 10.0.0.1): 10.0.20.1
Available rootfs storages: local-lvm local
Storage to use [local-lvm]: 
Using storage: local-lvm
Using template: local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst
</code>
</pre>

Once complete, Companion will be available at `http://<container-ip>:8000`.
