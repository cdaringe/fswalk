import fswalk
import gleam/iterator
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn walk_iter_test() {
  fswalk.builder()
  |> fswalk.with_path("test/fixture")
  |> fswalk.with_traversal_filter(fn(entry) {
    !string.contains(does: entry.filename, contain: "ignore_folder")
  })
  |> fswalk.walk
  |> iterator.fold([], fn(acc, it) {
    case it {
      Ok(entry) if !entry.stat.is_directory -> [entry.filename, ..acc]
      _ -> acc
    }
  })
  |> should.equal(["test/fixture/b/c/d", "test/fixture/a"])
}
