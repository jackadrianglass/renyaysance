{ pkgs, lib, config, inputs, ... }:

{
  packages = [ pkgs.git ];

  languages.gleam.enable = true;

  processes = {
    backend = {
        exec = "gleam run";
        cwd = "${config.git.root}/backend";
        watch = {
            paths = [ ./backend ];
            extensions = [ "gleam" "toml" ];
            ignore = [ "build" "priv" "manifest.toml" ];
        };
    };
    frontend = {
      exec = "gleam run -m lustre/dev build --outdir=${config.git.root}/backend/priv/static";
      cwd = "${config.git.root}/frontend";
      watch = {
        paths = [ ./frontend ];
        extensions = [ "gleam" ];
        ignore = [ "build" "priv" "manifest.toml" ];
      };
    };
  };
}
