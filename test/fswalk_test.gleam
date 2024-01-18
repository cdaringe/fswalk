import gleeunit
import gleeunit/should
import fswalk
import gleam/string
import gleam/iterator
import gleam/list

pub fn main() {
  gleeunit.main()
}

pub fn walk_iter_test() {
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
