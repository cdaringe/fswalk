import fswalk
import gleam/iterator
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn walk_iter_test() {
  fswalk.builder()
  |> fswalk.with_path("test/fixture")
  |> fswalk.with_entry_filter(fn(entry) {
    !string.contains(does: entry.filename, contain: "ignore_")
  })
  |> fswalk.with_traversal_filter(fn(entry) {
    !string.contains(does: entry.filename, contain: "ignore_folder")
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
