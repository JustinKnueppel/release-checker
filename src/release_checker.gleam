import gleam/io
import gleam/option
import gleam/result
import rc/commands
import rc/load
import rc/parse
import rc/types
import rc/util

pub fn main() {
  let repo = types.Repo("BurntSushi", "ripgrep")
  let saved = option.from_result(load.load_release_from_file("data/saved.json"))
  let new = result.unwrap(load.load_releases_from_file("data/new.json"), [])

  let new_releases = util.new_releases(new, saved)
  io.println(parse.marshal_releases(new_releases))
}
