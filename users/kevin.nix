{pkgs, ...}: {
  config = {
    users.users.kevin = {
      isNormalUser = true;
      description = "User for personal";
      extraGroups = ["networkmanager" "wheel"];
      packages = with pkgs; [
        firefox
        thunderbird
      ];
    };
  };
}
