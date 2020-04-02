import ./module.nix ({ packages, description, serviceConfig }:

{
  environment.systemPackages = packages;

  services.gnome3.gnome-keyring.enable = true;

  systemd.user.services.auto-fix-vsliveshare = {
    inherit description serviceConfig;
    wantedBy = [ "graphical-session.target" ];
  };
})
