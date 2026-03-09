{ pkgs, ... }:

let
  python = pkgs.python311;
in
{
  environment.systemPackages = [
    (python.withPackages (ps: with ps; [
      pip
      virtualenv
      setuptools
      build
      wheel
    ]))
  ];
}
