import ./module.nix ({ name, packages, description, serviceConfig }:

{
  environment.systemPackages = packages;

  services.gnome3.gnome-keyring.enable = true;

  systemd.user.services.${name} = {
    inherit description serviceConfig;
    wantedBy = [ "graphical-session.target" ];
  };
})
