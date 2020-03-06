import ./module.nix ({ packages, name, description, script }:

{
  home = { inherit packages; };

  services.gnome-keyring.enable = true;

  systemd.user.services.${name} = {
    Unit = {
      Description = description;
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${script}";
    };

    Install = {
      WantedBy = [ "graphical-session-pre.target" ];
    };
  };
})
