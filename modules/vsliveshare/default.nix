import ./module.nix ({ name, packages, description, serviceConfig }:

{
  environment.systemPackages = packages;

  services.gnome.gnome-keyring.enable = true;

  systemd.user.services.${name} = {
    inherit description serviceConfig;
    wantedBy = [ "graphical-session.target" ];
  };
})
