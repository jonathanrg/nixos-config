{ config, pkgs, pkgs-stable, ... }:

{
  ###########################################
  # Special configurations only for kratos #
  ###########################################

  # Hostname
  networking.hostName = "kratos";

  # Bridge connection
  networking.useDHCP = false;
  networking.bridges."br0".interfaces = [ "enp0s31f6" ];
  networking.interfaces."br0".ipv4.addresses = [{
    address = "10.18.8.103";
    prefixLength = 24;
  }];
  networking.defaultGateway = "10.18.8.1";
  networking.nameservers = [ "193.146.97.133" "193.146.97.132" ];


  # Thermald proactively prevents overheating on Intel CPUs and works well with other tools
  services.thermald.enable = true;

  # Special behaviours
  services.logind = {
    settings = {
      Login = {
        # When laptop lid is closed
        HandleLidSwitch = "suspend";
        # When power button is pushed
        HandlePowerKey = "suspend";
      };
    };    
  };

  # Special behaviour when laptop lid is closed
  # services.logind = {
  #   extraConfig = "HandlePowerKey=suspend";
  #   lidSwitch = "suspend";
  # };

  # Important: There is a problem related to the hardware of this
  # machine and the version of the kernel. Due to some incompatibilities
  # related to the GPU and CPU of this machine
  # CPU: Intel® Core™ i7 6700HQ - 4C/8T
  # GPU: Nvidia GTX 960M 2GB GDDR5 + Intel i915 (Skylake)
  # the highest version of the kernel supported is 6.4 so
  # it is necessary to let the laptop booting normally, select
  # a kernel lower than 6.4
  #boot.kernelPackages = pkgs.linuxPackages_6_1;
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs-stable.linuxPackages_zen;

  # Kernel parameters passed in GRUB in order to
  # allow the laptop starts normally due to the 
  # hardware of this machine
   boot.kernelParams = [ 
   ];

  # The current docker version is now working fine with Nvidia drivers
  virtualisation.docker.package = pkgs.docker;
  #virtualisation.docker.package = pkgs.docker_25;

  # Bluetooth support and management
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true;

  # List of packages installed in system profile only for this host
  environment.systemPackages = with pkgs; [
  ];

  # Creating a symlink for openjdk8 in order to configure Eclipse properly
  systemd.tmpfiles.rules = [
    "L /var/lib/jvm/openjdk8 - - - - ${pkgs-stable.jdk8}/lib/openjdk"
  ];

}
