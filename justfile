dev:
  gleam run -m lustre/dev start

check:
  watchexec -e gleam,css,toml gleam check

test:
  watchexec -e gleam,toml,mjs gleam test

review_snapshots:
  gleam run -m birdie
