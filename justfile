dev:
  gleam run -m lustre/dev start

check:
  watchexec -e gleam,css,toml gleam check
