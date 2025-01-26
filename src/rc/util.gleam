import birl
import gleam/list
import gleam/option
import gleam/order
import rc/types.{type Release}

pub fn newest_release(releases: List(Release)) -> option.Option(Release) {
  list.reduce(releases, fn(r1: Release, r2: Release) {
    case birl.compare(r1.published_at, r2.published_at) {
      order.Gt | order.Eq -> r1
      order.Lt -> r2
    }
  })
  |> option.from_result
}

pub fn new_releases(
  releases: List(Release),
  start: option.Option(Release),
) -> List(Release) {
  start
  |> option.map(fn(start_release) {
    use release <- list.filter(releases)
    order.Gt == birl.compare(release.published_at, start_release.published_at)
  })
  |> option.unwrap(releases)
}
