import ./module.nix ({ packages, description, script }:

{
  home = { inherit packages; };

  services.gnome-keyring.enable = true;

  systemd.user.services.auto-fix-vsliveshare = {
    Unit = {
      Description = description;
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = script;
    };

    Install = {
      WantedBy = [ "graphical-session-pre.target" ];
    };
  };
})
