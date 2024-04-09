{pkgs, ...}: {
  config = {
    users.users.kevin = {
      isNormalUser = true;
      description = "User for personal";
      extraGroups = ["networkmanager" "wheel"];
      shell = pkgs.fish;
    };

    programs.fish.enable = true;
  };
}
