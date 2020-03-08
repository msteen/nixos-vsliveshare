import ./module.nix ({ packages, description, script }:

{
  environment.systemPackages = packages;

  services.gnome3.gnome-keyring.enable = true;

  systemd.user.services.auto-fix-vsliveshare = {
    inherit description;
    serviceConfig = {
      ExecStart = script;
    };
    wantedBy = [ "graphical-session.target" ];
  };
})
