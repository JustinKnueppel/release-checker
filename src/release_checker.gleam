import birl
import gleam/bool
import gleam/dynamic
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import simplifile

pub fn main() {
  let filepath = "./data/data-2.json"
  let new_filepath = "./data/data.json"

  let newest_saved_release =
    load_releases(filepath)
    |> result.unwrap({
      io.println("Failed to find previous release list")
      []
    })
    |> newest_release

  io.println("Checking for new releases...")

  let newest_found_release =
    load_releases(new_filepath)
    |> result.unwrap({
      io.println("Failed to find current release list")
      []
    })
    |> newest_release

  let new_release = case newest_found_release, newest_saved_release {
    option.None, _ -> {
      io.println("No releases found")
      option.None
    }
    option.Some(release), option.None -> option.Some(release)
    option.Some(found_release), option.Some(saved_release) -> {
      case
        birl.compare(found_release.published_at, saved_release.published_at)
      {
        order.Gt -> option.Some(found_release)
        _ -> option.None
      }
    }
  }

  case new_release {
    option.Some(release) -> {
      io.println("New release: " <> release.tag_name)
    }
    _ -> Nil
  }

  // use saved_releases <- result.try(saved_releases)
  // marshal_releases(saved_releases) |> io.debug
  //
  // newest_release(saved_releases) |> io.debug

  // let releases =
  //   get_releases("GloriousEggroll", "proton-ge-custom")
  //   |> io.debug
  //
  // use releases <- result.try(releases)
  //
  // let res =
  //   marshal_releases(releases)
  //   |> simplifile.write(to: filepath, contents: _)
  //   |> result.map_error(DataSaveError)
  //
  // use <- bool.guard(result.is_error(res), res)
  //
  // io.println("Contents saved")

  Ok(Nil)
}

pub type Release {
  Release(tag_name: String, published_at: birl.Time)
}

pub type Error {
  ParseResponseError(dynamic.Dynamic)
  JsonParseError(json.DecodeError)
  DataSaveError(simplifile.FileError)
}

fn newest_release(releases: List(Release)) -> option.Option(Release) {
  list.reduce(releases, fn(r1: Release, r2: Release) {
    case birl.compare(r1.published_at, r2.published_at) {
      order.Gt | order.Eq -> r1
      order.Lt -> r2
    }
  })
  |> option.from_result
}

fn load_releases(filepath: String) -> Result(List(Release), Error) {
  simplifile.read(filepath)
  |> result.map_error(DataSaveError)
  |> result.try(parse_releases)
}

fn parse_releases(releases: String) -> Result(List(Release), Error) {
  let f = fn(d) {
    use x <- result.try(dynamic.string(d))
    birl.parse(x)
    |> result.map_error(fn(_) {
      [dynamic.DecodeError("Valid time string", x, [])]
    })
  }
  let release_decoder =
    dynamic.decode2(
      Release,
      dynamic.field("tag_name", of: dynamic.string),
      dynamic.field("published_at", of: f),
    )

  let releases_decoder = dynamic.list(release_decoder)

  json.decode(from: releases, using: releases_decoder)
  |> result.map_error(JsonParseError)
}

fn marshal_releases(releases: List(Release)) -> String {
  json.array(releases, of: marshal_release)
  |> json.to_string()
}

fn marshal_release(release: Release) -> json.Json {
  json.object([
    #("tag_name", json.string(release.tag_name)),
    #("published_at", json.string(birl.to_iso8601(release.published_at))),
  ])
}

fn get_releases(owner: String, repo: String) -> Result(List(Release), Error) {
  let uri =
    "https://api.github.com/repos/" <> owner <> "/" <> repo <> "/releases"
  let assert Ok(req) = request.to(uri)

  use res <- result.try(httpc.send(req) |> result.map_error(ParseResponseError))

  parse_releases(res.body)
}
