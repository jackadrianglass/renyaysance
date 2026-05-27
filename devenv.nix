{ pkgs, lib, config, inputs, ... }:

{
  packages = [ pkgs.git pkgs.cowsay ];

  languages.gleam.enable = true;

  processes = {
    app = {
        exec = "cowsay $(date +%Y%m%d%H%M%S) && cd ./frontend && gleam run -m lustre/dev build --outdir=../backend/priv/static && cd ../backend && gleam run";
        watch = {
            paths = [ ./backend ./frontend ];
            extensions = [ "gleam" ];
            ignore = [ "build" "priv" "manifest.toml" ];
        };
    };
  };
}
