import birl
import gleam/dynamic
import gleam/json
import gleam/result
import rc/types.{type Release, Release}

pub type Error {
  JsonParseError(json.DecodeError)
}

fn release_decoder() -> fn(dynamic.Dynamic) ->
  Result(Release, List(dynamic.DecodeError)) {
  let f = fn(d) {
    use x <- result.try(dynamic.string(d))
    birl.parse(x)
    |> result.map_error(fn(_) {
      [dynamic.DecodeError("Valid time string", x, [])]
    })
  }

  dynamic.decode2(
    Release,
    dynamic.field("tag_name", of: dynamic.string),
    dynamic.field("published_at", of: f),
  )
}

pub fn parse_release(release: String) -> Result(Release, Error) {
  json.decode(from: release, using: release_decoder())
  |> result.map_error(JsonParseError)
}

pub fn parse_releases(releases: String) -> Result(List(Release), Error) {
  json.decode(from: releases, using: dynamic.list(release_decoder()))
  |> result.map_error(JsonParseError)
}

pub fn marshal_release(release: Release) -> json.Json {
  json.object([
    #("tag_name", json.string(release.tag_name)),
    #("published_at", json.string(birl.to_iso8601(release.published_at))),
  ])
}

pub fn marshal_releases(releases: List(Release)) -> String {
  json.array(releases, of: marshal_release)
  |> json.to_string()
}
