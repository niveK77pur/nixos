{
  lib,
  runCommand,
  writers,
  makeWrapper,
  xxhash,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  diffutils,
  gawk,
  supernote-tool,
}: let
  scriptName = "supernote-recursive-conversion";
  script = writers.writeFishBin scriptName (builtins.readFile ./supernote-recursive-conversion.fish);
in
  runCommand scriptName {nativeBuildInputs = [makeWrapper];} ''
    makeWrapper \
      ${script}/bin/${scriptName} \
      $out/bin/${scriptName} \
      --prefix PATH : ${lib.makeBinPath [xxhash coreutils findutils gnugrep gnused diffutils gawk supernote-tool]}
  ''
