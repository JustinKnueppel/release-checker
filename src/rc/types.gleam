import birl

pub type Repo {
  Repo(user: String, name: String)
}

pub type Release {
  Release(tag_name: String, published_at: birl.Time)
}
