# NeheOpenglElixir

A port of [nehe_erlang](https://github.com/asceth/nehe_erlang).

## Play

```sh
iex -S mix
```

```elixir
gc = GameCore.start_link
GameCore.load(gc, Lesson02)
```

You can edit the `lesson02.ex` module and recompile it in the shell, and it will
live-update, so that's cool.
