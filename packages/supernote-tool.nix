{
  lib,
  python3,
  fetchFromGitHub,
  callPackage,
  potracer ? callPackage ./python3-potracer.nix {},
}:
python3.pkgs.buildPythonPackage rec {
  pname = "supernote-tool";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "jya-dev";
    repo = "supernote-tool";
    rev = "v${version}";
    sha256 = "sha256-rB6kOJDWvxXaXGiTDI8/+hJDtqCssRUAZ5uNCJM+3aw=";
  };

  pyproject = true;
  build-system = with python3.pkgs; [hatchling];

  propagatedBuildInputs = with python3.pkgs; [
    colour
    fusepy
    numpy
    pillow
    potracer
    pypng
    reportlab
    svglib
    svgwrite
  ];

  meta = with lib; {
    description = "Unofficial python tool for Supernote";
    license = licenses.asl20;
    homepage = "https://github.com/jya-dev/supernote-tool";
    mainProgram = pname;
    platforms = platforms.all;
  };
}
