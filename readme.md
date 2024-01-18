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
    |> fswalk.with_filter(fn(entry) {
      !string.contains(does: entry.filename, contain: "ignore")
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

Further documentation can be found at <https://hexdocs.pm/fswalk>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
