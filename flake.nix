{
  description = "A busybox/LFS distro aimed to explore virtualized environments";

  # inputs = {
  #   flake-utils.url = "github:numtide/flake-utils";

  #   # 0.14.0
  #   # zig-nixpkgs.url = "github:NixOS/nixpkgs/SHA";
  # };

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }@inputs :
    flake-utils.lib.eachDefaultSystem (system:
    let
      zig-nixpkgs = inputs.zig-nixpkgs.legacyPackages.${system} or pkgs;
    in
     {
       devShells.default = nixpkgs.mkShell {
         packages = [
           zigPkgs.zig,
           pkgs.fzf
           pkgs.tree
           pkgs.tmux
           pkgs.testdisk
           pkgs.ddate
         ];

         shellHook = ''
           echo "zig" "$(zig version)"
         '';
       };
    });

    # Name your host machine
    networking.hostName = "kjx";

    # Set your time zone.
    time.timeZone = "America/Sao_Paulo";

    # Enter keyboard layout
    services.xserver.layout = "br";
    services.xserver.xkbVariant = "abnt2";

    # Define user accounts
    users.extraUsers =
        {
            myuser =
            {
                extraGroups = [ "wheel" "networkmanager" ];
                isNormalUser = true;
            };
        };

    # Install some packages
    environment.systemPackages =
            with pkgs;
            [
                ddate
                testdisk
                fzf
                tree
                tmux
            ];

    # =========
    # Dropbear Setup
    # ===============

    # Enable the dropbear daemon
    services.dropbear.enable = true;

    # additional hardware configuration not discovered by hardware scan
    boot.initrd.availableKernelModules = [
        "virtio-pci",
        "bridge",
        "br_netfilter",
        "veth",
        "tun",
        "overlay",
        "iptable_nat",
        "iptable_security",
        "ip6table_security",
        "xt_nat",
        "xt_MASQUERADE",
        "xt_addrtype",
        "xt_multiport",
        "xt_mark",
        "xt_ipvs",
        "xt_comment",
        "xt_cgroup",
        "xt_bpf",
        "xt_SECMARK",
        "xt_REDIRECT",
        "xt_LOG",
        "xt_CONNSECMARK",
        "nf_log_syslog",
        "ip_set",
        "ip_vs",
        "ip_vs_rr",
        "cls_bpf",
        "cls_cgroup",
        "act_bpf",
        "vxlan",
        "udp_tunnel",
        "ip6_udp_tunnel",
        "esp4",
        "macsec",
        "stp",
        "p8022",
        "psnap",
        "llc",
        "ebtables",
        "rpcsec_gss_krb5",
        "auth_rpcgss",
        "intel_vsec",
        "x86_pkg_temp_thermal",
        "efivarfs",
        ];

    boot.initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        hostECDSAKey = /var/src/secrets/dropbear/ecdsa-hostkey;
        # this includes the ssh keys of all users in the wheel group, but you can just specify some keys manually
        # authorizedKeys = [ "ssh-rsa ..." ];
        authorizedKeys = with lib; concatLists (mapAttrsToList (name: user: if elem "wheel" user.extraGroups then user.openssh.authorizedKeys.keys else []) config.users.users);
      };
      postCommands = ''
        echo 'cryptsetup-askpass' >> /home/kjx/.profile
      '';
    };

}
