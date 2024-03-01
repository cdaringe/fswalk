# fswalk

Recursively walk the filesystem starting from the provided path.

[![Package Version](https://img.shields.io/hexpm/v/fswalk)](https://hex.pm/packages/fswalk)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/fswalk/)

```sh
gleam add fswalk
```

```gleam
import fswalk

pub fn main() {
  fswalk.builder()
    |> fswalk.with_path("test/fixture")
    |> fswalk.with_entry_filter(fn(entry) {
      !string.contains(does: entry.filename, contain: "ignore")
    })
    |> fswalk.with_traversal_filter(fn(entry) {
      !string.contains(does: entry.filename, contain: "build")
    })
    |> fswalk.walk
    |> iterator.map(fn(it) {
      let assert Ok(entry) = it
      entry.filename
    })
    |> iterator.to_list
    |> list.sort(string.compare)
    |> should.equal([
      "test/fixture/a", "test/fixture/b", "test/fixture/b/c", "test/fixture/b/c/d",
    ])
}
```

You can set `DEBUG=1` to see all result of every file visited.

Further documentation can be found at <https://hexdocs.pm/fswalk>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## changelog

- 1.0.0 - init
- 2.0.0 - support traverse filtering in tandem with entry filtering
