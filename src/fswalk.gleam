import gleam/list
import gleam/iterator.{type Iterator}
import gleam/option.{type Option, None, Some}
import gleam_community/path
import simplifile.{type FileError, is_directory, read_directory}

pub opaque type Non

pub opaque type Som

pub opaque type WalkBuilder(filter, path) {
  WalkBuilder(filter: Option(EntryFilter), path: Option(String))
}

pub fn builder() -> WalkBuilder(Non, Non) {
  WalkBuilder(filter: None, path: None)
}

pub fn with_path(wb: WalkBuilder(f, p), path: String) -> WalkBuilder(f, Som) {
  WalkBuilder(filter: wb.filter, path: Some(path))
}

pub fn with_filter(
  wb: WalkBuilder(f, p),
  filter: EntryFilter,
) -> WalkBuilder(Som, p) {
  WalkBuilder(filter: Some(filter), path: wb.path)
}

pub fn walk(wb: WalkBuilder(f, Som)) {
  let WalkBuilder(filter: filter_opt, path: path_opt) = wb
  let assert Some(root_path) = path_opt
  let filter: EntryFilter = case filter_opt {
    Some(f) -> f
    _ -> fn(_) { True }
  }
  walk_path(path.from_string(root_path), filter)
}

pub type Stat {
  Stat(is_directory: Bool)
}

pub type Entry {
  Entry(filename: String, stat: Stat)
}

pub type EntryFilter =
  fn(Entry) -> Bool

fn to_entry(filename: String) -> Entry {
  Entry(filename: filename, stat: Stat(is_directory: is_directory(filename)))
}

fn path_to_entry(pth: path.Path) -> Entry {
  to_entry(path.to_string(pth))
}

fn ok(x) {
  Ok(x)
}

// walk the fs, starting at pth.
//
fn walk_path(
  pth: path.Path,
  filter: EntryFilter,
) -> Iterator(Result(Entry, FileError)) {
  iterator.once(fn() { read_directory(at: path.to_string(pth)) })
  |> iterator.flat_map(fn(readdir_result) {
    case readdir_result {
      Error(x) -> iterator.once(fn() { Error(x) })
      Ok(filenames) -> {
        let #(allpaths, folderpaths) =
          list.fold(filenames, #([], []), fn(acc, f) {
            let filepath = path.append_string(pth, f)
            let next_allpaths = [filepath, ..acc.0]
            case is_directory(path.to_string(filepath)) {
              True -> #(next_allpaths, [filepath, ..acc.1])
              False -> #(next_allpaths, acc.1)
            }
          })
        let ok_entries =
          allpaths
          |> list.map(path_to_entry)
          |> list.filter(fn(entry) { filter(entry) })
          |> list.map(ok)
          |> iterator.from_list
        iterator.concat([
          ok_entries,
          ..list.map(folderpaths, fn(fp) { walk_path(fp, filter) })
        ])
      }
    }
  })
}
