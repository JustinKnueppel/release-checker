import gleam/result
import rc/parse
import rc/types.{type Release}
import simplifile

pub type Error {
  DataSaveError(simplifile.FileError)
  DataLoadError(simplifile.FileError)
  DataParseError(parse.Error)
}

pub fn load_release_from_file(filepath: String) -> Result(Release, Error) {
  simplifile.read(filepath)
  |> result.map_error(DataLoadError)
  |> result.then(fn(contents) {
    parse.parse_release(contents)
    |> result.map_error(DataParseError)
  })
}

pub fn load_releases_from_file(filepath: String) -> Result(List(Release), Error) {
  simplifile.read(filepath)
  |> result.map_error(DataLoadError)
  |> result.then(fn(contents) {
    parse.parse_releases(contents)
    |> result.map_error(DataParseError)
  })
}

pub fn write_releases(
  filepath: String,
  releases: List(Release),
) -> Result(Nil, Error) {
  simplifile.write(filepath, parse.marshal_releases(releases))
  |> result.map_error(DataSaveError)
}
