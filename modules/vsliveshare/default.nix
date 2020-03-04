import ./module.nix ({ packages, name, description, script }:

{
  environment.systemPackages = packages;

  services.gnome3.gnome-keyring.enable = true;

  systemd.user.services.${name} = {
    inherit description;
    serviceConfig = {
      ExecStart = script;
    };
    wantedBy = [ "graphical-session.target" ];
  };
})
