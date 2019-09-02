# emergency-kexec

Okay, your system is completely broken, and you need to umount `/` or something like that.
What do you do?

## Motivation

One of our servers had a broken root filesystem (btrfs, don't judge me).
Online recovery was not possible, so the filesystem needed to be unmounted which is not possible for the root fs.
Additionally, as errors were detected, the kernel decided to mount it read only and didn't let me remount it as `rw`.
IPMI? Yes, I had the password in my password store but not the username.
So the only logical solution was to kexec into an emergency system.
This code is what I used.
It recovers all IP addresses as well as SSH host and user keys from the old system and kexecs into a new one - entirely in-memory.

## What it does

The `emergency` script (found in the repository root) will SSH over and execute the following things:

1. Build the recovery image (a `.tar.xz` with a small nix store and a `kexec` script) from the files in this repository
	1. The system configuration is found in `configuration.nix`
	2. Some `kexec`-related features are imported from `kexec.nix`
	3. The scripts will be included to be used in the `kexec` script (see below)
2. Try to `mkdir` `/nix` and `/tmp`. If the don't already exist and your root fs is read-only, you have a problem
3. Mount a fresh `tmpfs` on `/tmp` because there might not be one already
4. `scp` the emergency image over and extract it
5. Mount the nix store from the emergency image over `/nix` using `overlayfs`
6. Run the kexec script

The `kexec` script (found in `kexec.nix`) will do the following:

1. Prepare a second initrd
2. Put your SSH host keys into the initrd
3. Put all of your SSH user keys into the initrd
4. Fetch all your IP addresses and routes and put them into the initrd
5. Pack the second initrd and append it to the default NixOS initrd from the emergency image
6. `kexec` into the kernel from the emergency image while using the new initrd
7. In case you didn't already notice: **This will crash your currently running system, so maybe it's a good idea to gracefully shut down remaining daemons if that's still possible**

The script that is packed into the initrd of the new system will do the following:

1. Place the SSH host key
2. Place the SSH user keys
3. Place a script for the IP addresses which will be executed using `networking.localCommands` so the interfaces are available

## How to use

```
$ ./emergency root@somehost 0
# or
$ ./emergency somebody@somehost 1

# To force an image rebuild:
$ rm ./result
```

## Disclaimer and license

If it doesn't work for you, I'm sorry.
I can probably not help you, but if you're able to fix something, feel free to create a PR.

The code is based on [clever's](https://github.com/cleverca22) kexec nix-test (found [here](https://github.com/cleverca22/nix-tests/tree/master/kexec)).

The code is licensed under the [LGPL3](LICENSE).
