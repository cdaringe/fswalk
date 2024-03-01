import gleam/list
import gleam/iterator.{type Iterator}
import gleam/result
import gleam/option.{type Option, None, Some}
import gleam_community/path
import simplifile.{type FileError, verify_is_directory, read_directory}

/// Private. Pending [gleam/issues/2486](https://github.com/gleam-lang/gleam/issues/2486)
///
pub opaque type Non

/// Private. Pending [gleam/issues/2486](https://github.com/gleam-lang/gleam/issues/2486)
///
pub opaque type Som

/// See [builder](#builder).
///
pub opaque type WalkBuilder(entry_filter, traversal_filter, path) {
  WalkBuilder(
    entry_filter: Option(List(EntryFilter)),
    traversal_filter: Option(List(EntryFilter)),
    path: Option(String),
  )
}

/// Create a new WalkBuilder
///
pub fn builder() -> WalkBuilder(Non, Non, Non) {
  WalkBuilder(entry_filter: None, traversal_filter: None, path: None)
}

/// Create a new WalkBuilder bound to a directory path to walk
///
pub fn with_path(
  builder: WalkBuilder(f, t, p),
  path: String,
) -> WalkBuilder(f, t, Som) {
  WalkBuilder(
    entry_filter: builder.entry_filter,
    traversal_filter: builder.traversal_filter,
    path: Some(path),
  )
}

/// Create a new WalkBuilder adding an additional entry filter function.
///
pub fn with_entry_filter(
  builder: WalkBuilder(f, t, p),
  entry_filter: EntryFilter,
) -> WalkBuilder(Som, t, p) {
  WalkBuilder(
    entry_filter: Some(
      list.append(option.unwrap(builder.entry_filter, []), [entry_filter]),
    ),
    traversal_filter: builder.traversal_filter,
    path: builder.path,
  )
}

/// Create a new WalkBuilder adding an additional entry filter function.
///
pub fn with_traversal_filter(
  builder: WalkBuilder(f, t, p),
  traversal_filter: EntryFilter,
) -> WalkBuilder(f, Som, p) {
  WalkBuilder(
    entry_filter: builder.entry_filter,
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
pub fn walk(builder: WalkBuilder(f, t, Som)) {
  let WalkBuilder(
    entry_filter: entry_filter_opt,
    traversal_filter: traversal_filter_opt,
    path: path_opt,
  ) = builder
  let assert Some(root_path) = path_opt
  let entry_filters: List(EntryFilter) = case entry_filter_opt {
    Some(xs) -> xs
    _ -> []
  }
  let traversal_filters: List(EntryFilter) = case traversal_filter_opt {
    Some(xs) -> xs
    _ -> []
  }
  walk_path(path.from_string(root_path), entry_filters, traversal_filters)
}

// Needs beefing up.
/// Weak [stat](https://www.man7.org/linux/man-pages/man2/stat.2.html) implementation.
///
pub type Stat {
  Stat(is_directory: Bool)
}

pub type Entry {
  Entry(filename: String, stat: Stat)
}

pub type EntryFilter =
  fn(Entry) -> Bool

fn to_entry(filename: String) -> Entry {
  Entry(filename: filename, stat: Stat(is_directory: verify_is_directory(filename) |> result.unwrap(or: False)))
}

fn path_to_entry(pth: path.Path) -> Entry {
  to_entry(path.to_string(pth))
}

fn ok(x) {
  Ok(x)
}

fn filter_many(xs, filters) {
  xs
  |> list.filter(fn(entry) { list.all(filters, fn(f) { f(entry) }) })
}

fn to_ok_iter(xs) {
  xs
  |> list.map(ok)
  |> iterator.from_list
}

/// walk the fs, starting at the provided path.
///
fn walk_path(
  pth: path.Path,
  entry_filters: List(EntryFilter),
  traversal_filters: List(EntryFilter),
) -> Iterator(Result(Entry, FileError)) {
  iterator.once(fn() { read_directory(at: path.to_string(pth)) })
  |> iterator.flat_map(fn(readdir_result) {
    case readdir_result {
      Error(x) -> iterator.once(fn() { Error(x) })
      Ok(filenames) -> {
        let #(filepaths, folderpaths) =
          list.fold(filenames, #([], []), fn(acc, f) {
            let filepath = path.append_string(pth, f)
            case verify_is_directory(path.to_string(filepath)) |> result.unwrap(or: False) {
              True -> #(acc.0, [filepath, ..acc.1])
              False -> #([filepath, ..acc.0], acc.1)
            }
          })
        let ok_filtered_files =
          filepaths
          |> list.map(path_to_entry)
          |> filter_many(entry_filters)
          |> to_ok_iter

        let candidate_folder_entries: List(Entry) =
          folderpaths
          |> list.map(path_to_entry)

        let ok_filtered_folders =
          candidate_folder_entries
          |> filter_many(entry_filters)
          |> to_ok_iter

        let traverse_folders =
          candidate_folder_entries
          |> filter_many(traversal_filters)

        iterator.concat([
          ok_filtered_files,
          ok_filtered_folders,
          ..list.map(traverse_folders, fn(ent) {
            walk_path(
              path.from_string(ent.filename),
              entry_filters,
              traversal_filters,
            )
          })
        ])
      }
    }
  })
}

//
/// Sugar method for consuming the walk iterator instance
pub fn each(it, fun) {
  it
  |> iterator.each(fun)
}

//
/// Sugar method for consuming the walk iterator instance
pub fn map(it, fun) {
  it
  |> iterator.map(fun)
}

//
/// Sugar method for consuming the walk iterator instance
pub fn fold(it, init, fun) {
  it
  |> iterator.fold(init, fun)
}

/// Handy EntryFilter
pub fn only_dirs(ent: Entry) {
  ent.stat.is_directory
}

/// Handy EntryFilter
pub fn only_files(ent: Entry) {
  !only_dirs(ent)
}
