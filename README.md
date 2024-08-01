# Kate's Nix Dotfiles
My personal Nix dotfiles that currently serves: 1 laptop, and some rapidly growing number of VM and LXCs running on Proxmox.

With my current nix obsession I expect there to be a lot more soon...

> Note that this is not intended to be the gold standard of dotfiles. I'm almost certainly doing things poorly, inefficently, or just otherwise *weirdly*. This repo is currently still decently messy, and subject to major structural changes as I get more used to Nix.

## Features
- Multi-machine NixOS system configurations
- **home-manager** as a NixOS module
- **sops-nix** in both NixOS and home-manager
- Both desktop and server configurations
- Server configurations for both proxmox **lxc** and **vm**
- Seperate **sops-nix** private repo as an input
- Non ssh host keys for **sops-nix**


## Definitions
I'm probably using some non-standard definitions in my dotfiles. 
In my opinion, these are more conceptual and *"vibes"* based.

- **Modules**: small, reusable modules that would be expected to be used and reused in a variety of places.
Funnily enough, they are supposed to be modular. 
Think things like, `zsh`, or `ssh`. 
Small additions that a machine *has* but isn't what it *does*.

- **Roles**: larger collections of modules which are typically used in one specific circumstance, ie. `desktop/gnome`, or `proxy`. 
These are pretty much well defined, opinionated full setups rather than the smaller modules which define one specifc thing. 
For instance in a lot of the server roles, we're defining the service it uses (say, Authelia), plus backing up those config/data files, plus doing x, oh and y. 
These are the things that it *does*; the kind of things that you look at a machine and you go "Oh that is the `x` machine. This is the proxy, this is the desktop".
There can be multiple roles for a given system.

Both `roles` and `modules` are actually just nix modules. It is just how I've intuitively organised them.


## Initial setup
Initial setup *should* be straight forward. Add your system (and probably remove others!) to the `systems` variable in flake.nix, defining:
```
  "[hostname]" = {
    hostType = [physical|servers];
    # Roles that the system may use (can also define modules)
    roles = [
      ./nixos/roles/some-role
    ];
    usesHomeManager = [default true for physical devices, default false for servers];
    # Home-manager roles
    hmRoles = [
      ./home-manager/roles/some-other-role
    ];
  };
```
If you're not going to strip out `sops-nix` then read the [Secrets](#secrets) section.

### If you're me
Once you've added the system, deploy (via ansible or otherwise) the machine-specific sops-age key to `/etc/sops-age.txt`.
SSH or login to the system with a yubikey plugged in, and `nix-rebuild switch --flake /etc/nixos#[hostname]`. 

Use the yubikey to pull the nix-secrets repo.
Alternatively, use the github deploy key for the nix-secrets repo to access the repo via SSH.
All that should be required on a new system is the sops-age key, and either the yubikey or the nix-secrets github read-only deploy key


### Secrets
You'll need to replace the flake input **nix-secrets** if you want to keep using sops-nix.
This is a private repo which contains just the standard sops configuration - nothing specific to nix.
You also could just put all your secrets (encrypted!!!) with sops-nix in your repo. It's done by a *lot* of people. But I have trust issues.


I'm using pre-generated keys for a given system.
The big reason for this is particularly the servers.
This allows me to 
1. Generate the keys for a system, 
2. Pop them into the sops config, 
3. Add it to my provisioning scripts (currently ansible, but I have my eyes on you morph and terraform),
4. Deploy a fresh vm or lxc from a golden image with the provisioning script, and during that, add the given key for that host
5. Using either ansible or just plain old `        nixos-rebuild --target-host x switch`, deploy this flake

To me, this is a much more reasonable and fluid workflow than spinning up the lxc/vm, getting the host key, putting that in sops... agony. Especially if you're doing that a lot!!




## Server Provisioning
The initial intent of this flake was purely server configuration and provisioning. 
My rapid obsession with nix has meant that this has expanded into other machines too.
However, the primary focus of this was to generate reproducible, simple, modular VMs and LXCs for my home servers running proxmox.

### Golden image
The top level `golden.nix` is a very basic nix configuration. It defines a super simple, SSH enabled NixOs host. 
In my [ansible scripts]("https://github.com/CertifiKate/HomeServer") (Warning, it's a mess), I run `nixos-generators` with either proxmox-lxc or proxmox tempaltes and specify the golden.nix file.
This auto copies the generated image/template to the proxmox storage
When provisioning an LXC or VM, this generated image/template is used, and provides a super simple groundwork for us to convert it into a specialised configuration (ie. proxy server, or authentication server)

### To Do
Add details about:
- Ansible server provisioning to proxmox
- Getting age keys deployed
- Get some nix-ops system running on `build-01` to handle everything from lxc/vm provisioning to nixos configuration deployment.
 Also handle the keys for initial deployment (use github deploy token instead of yubikey?) 