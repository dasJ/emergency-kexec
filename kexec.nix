{ config, pkgs, ... }: {
  system.build = rec {
    image = pkgs.runCommand "image" { buildInputs = [ pkgs.nukeReferences ]; } ''
      mkdir "$out"
      cp "${config.system.build.kernel}/bzImage" "$out/kernel"
      cp "${config.system.build.netbootRamdisk}/initrd" "$out/initrd"
      echo "init=${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init ${toString config.boot.kernelParams}" > "$out/cmdline"
      nuke-refs "$out/kernel"
    '';

    kexecScript = pkgs.writeScript "kexec-nixos" ''
      #!${pkgs.stdenv.shell}

      export PATH="${pkgs.kexectools}/bin:${pkgs.cpio}/bin:$PATH"

      cd $(mktemp -d)
      mkdir initrd
      pushd initrd
      cat /etc/ssh/ssh_host_ed25519_key > ed25519_host_key
      cat /etc/ssh/ssh_host_ed25519_key.pub > ed25519_host_key.pub
      ${./ip-to-ip} > ip-script
      ${./ssh-keys} > ssh-keys 2>&1
      chmod 755 ip-script
      find -type f | cpio -o -H newc | gzip -9 > ../extra.gz
      popd
      cat "${image}/initrd" extra.gz > final.gz

      kexec -l "${image}/kernel" --initrd=final.gz --append="init=${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init ${toString config.boot.kernelParams}"
      systemd-run --on-active=2 --timer-property=AccuracySec=100ms $(which kexec) -e
    '';
  };

  boot.initrd.postMountCommands = ''
    mkdir -p /mnt-root/etc/ssh /mnt-root/root/.ssh
    umask 077
    cat /ed25519_host_key > /mnt-root/etc/ssh/ssh_host_ed25519_key
    cat /ed25519_host_key.pub > /mnt-root/etc/ssh/ssh_host_ed25519_key.pub
    cat /ssh-keys > /mnt-root/root/.ssh/authorized_keys
    cat /ip-script > /mnt-root/kexec-ips
  '';

  networking.localCommands = ''
    export PATH="${pkgs.iproute}/bin:$PATH"
    . /kexec-ips
  '';

  system.build.kexec_tarball = pkgs.callPackage <nixpkgs/nixos/lib/make-system-tarball.nix> {
    storeContents = [
      { object = config.system.build.kexecScript; symlink = "/kexec"; }
    ];
    contents = [];
  };
}
