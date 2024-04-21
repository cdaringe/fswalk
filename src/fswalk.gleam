import gleam/iterator.{type Iterator}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam_community/path
import simplifile.{type FileError, read_directory, verify_is_directory}

@internal
pub type Non

@internal
pub type Som

/// See [builder](#builder).
///
pub opaque type WalkBuilder(traversal_filter, path) {
  WalkBuilder(traversal_filter: Option(List(EntryFilter)), path: Option(String))
}

/// Create a new WalkBuilder
///
pub fn builder() -> WalkBuilder(Non, Non) {
  WalkBuilder(traversal_filter: None, path: None)
}

/// Create a new WalkBuilder bound to a directory path to walk
///
pub fn with_path(
  builder: WalkBuilder(t, p),
  path: String,
) -> WalkBuilder(t, Som) {
  WalkBuilder(traversal_filter: builder.traversal_filter, path: Some(path))
}

/// Create a new WalkBuilder adding an additional entry filter function.
///
pub fn with_traversal_filter(
  builder: WalkBuilder(t, p),
  traversal_filter: EntryFilter,
) -> WalkBuilder(Som, p) {
  WalkBuilder(
    traversal_filter: Some(
      list.append(option.unwrap(builder.traversal_filter, []), [
        traversal_filter,
      ]),
    ),
    path: builder.path,
  )
}

/// Walks the filesystem lazily.
///
pub fn walk(builder: WalkBuilder(t, Som)) {
  let WalkBuilder(traversal_filter: traversal_filter_opt, path: path_opt) =
    builder
  let assert Some(root_path) = path_opt
  let traversal_filters = case traversal_filter_opt {
    Some(xs) -> xs
    _ -> []
  }
  walk_path(path.from_string(root_path), traversal_filters)
}

/// Incomplete [stat](https://www.man7.org/linux/man-pages/man2/stat.2.html) data.
///
pub type Stat {
  Stat(is_directory: Bool)
}

//
/// Data about the file/folder walked.
pub type Entry {
  Entry(filename: String, stat: Stat)
}

//
/// A function that filters entries in the walk iterator.
pub type EntryFilter =
  fn(Entry) -> Bool

fn to_entry(path: path.Path) -> Entry {
  let filename = path.to_string(path)
  Entry(
    filename,
    stat: Stat(
      is_directory: verify_is_directory(filename)
      |> result.unwrap(or: False),
    ),
  )
}

fn filter_many(xs, filters) {
  xs
  |> list.filter(fn(entry) { list.all(filters, fn(f) { f(entry) }) })
}

/// Walk the filesystem, starting at the provided path.
///
fn walk_path(
  pth: path.Path,
  traversal_filters: List(EntryFilter),
) -> Iterator(Result(Entry, FileError)) {
  iterator.once(fn() { read_directory(at: path.to_string(pth)) })
  |> iterator.flat_map(fn(readdir_result) {
    readdir_result
    |> result.map_error(fn(e) { iterator.once(fn() { Error(e) }) })
    |> result.map(fn(basenames) {
      let paths =
        list.map(basenames, fn(basename) { path.append_string(pth, basename) })
      let #(all_entries, dir_entries) =
        list.fold(paths, #([], []), fn(acc, it) {
          let entry = to_entry(it)
          let is_dir =
            verify_is_directory(path.to_string(it))
            |> result.unwrap(or: False)
          #([entry, ..acc.0], case is_dir {
            True -> [entry, ..acc.1]
            False -> acc.1
          })
        })
      let traverse_dirs = filter_many(dir_entries, traversal_filters)
      iterator.concat([
        iterator.from_list(list.map(all_entries, fn(it) { Ok(it) })),
        ..list.map(traverse_dirs, fn(ent) {
          walk_path(path.from_string(ent.filename), traversal_filters)
        })
      ])
    })
    |> result.unwrap_both
  })
}
