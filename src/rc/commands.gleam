import gleam/dynamic
import gleam/http/request
import gleam/httpc
import gleam/result
import rc/parse
import rc/types.{type Release, type Repo}

pub type Command {
  AllReleases(Repo)
}

pub type Error {
  HttpError(dynamic.Dynamic)
  ParseResponseError(parse.Error)
}

pub fn all_releases(repo: Repo) -> Result(List(Release), Error) {
  let uri =
    "https://api.github.com/repos/"
    <> repo.user
    <> "/"
    <> repo.name
    <> "/releases"
  let assert Ok(req) = request.to(uri)

  use res <- result.try(httpc.send(req) |> result.map_error(HttpError))

  parse.parse_releases(res.body)
  |> result.map_error(ParseResponseError)
}
