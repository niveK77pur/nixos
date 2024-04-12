{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      mpv
      yt-dlp
      ani-cli
      kdePackages.kdeconnect-kde
      # anime4k
    ];

    networking.firewall = {
      enable = true;
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
    };
  };
}
