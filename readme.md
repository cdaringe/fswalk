# fswalk

Recursively walk the filesystem starting from the provided path.

[![Package Version](https://img.shields.io/hexpm/v/fswalk)](https://hex.pm/packages/fswalk)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/fswalk/)

```sh
gleam add fswalk
```

```gleam
import fswalk
import gleam/yielder

pub fn main() {
  fswalk.builder()
  |> fswalk.with_path("test/fixture")
  |> fswalk.with_traversal_filter(fn(entry) {
    !string.contains(does: entry.filename, contain: "ignore_folder")
  })
  |> fswalk.walk
  |> yielder.fold([], fn(acc, it) {
    case it {
      Ok(entry) if !entry.stat.is_directory -> [entry.filename, ..acc]
      _ -> acc
    }
  })
  |> should.equal(["test/fixture/b/c/d", "test/fixture/a"])
}
```

Further documentation can be found at <https://hexdocs.pm/fswalk>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## changelog

- 1.0.0 - init
- 2.0.0 - support traverse filtering in tandem with entry filtering
- 3.0.0
  - dropped `.with_entry_filter`. Use `iterator.*` functions on the output instead.
  - dropped sugar functions `.map/.each/.fold`. Use `iterator.*` functions on the output instead.
- 3.0.3
  - Use `yielder.*` functions on the output instead of `iterator.*`
