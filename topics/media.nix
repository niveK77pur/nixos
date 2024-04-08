{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      mpv
      yt-dlp
      ani-cli
      # anime4k
    ];
  };
}
