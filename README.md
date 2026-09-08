# proxmox-companion
Shell script to install [Bitfocus Companion](https://bitfocus.io/companion) in a Proxmox LXC container.

The script will:
- Detect a storage that supports container root filesystems (preferring `local-lvm`, then `local`), prompting if more than one is available
- Detect a storage that supports templates, and reuse an existing Debian template or automatically download one matching your host's architecture (prefers Debian 12; override with `PREFERRED_DEBIAN=13`)
- Create and start the container, wait for it to boot, and install Companion inside it
- Enable Companion to start on boot

No manual template download is required.

## Usage

Run the following command within the Proxmox `>_ Shell` and follow the prompts for container number, name, password, and network configuration (DHCP or a static IP/gateway):

<pre>
<code>bash -c "$(wget -qLO - https://raw.githubusercontent.com/infocusav/proxmox-companion/main/install-companion.sh)"
</code>
</pre>

Once complete, Companion will be available at `http://<container-ip>:8000`.
