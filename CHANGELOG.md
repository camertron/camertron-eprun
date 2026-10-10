== 2.0.0
* Removed MRI 1.8 compatibility.
* Big internal refactor, but same API.
* Support multiple versions of the Unicode Character Database (UCD), including the latest (v18.0.0).
* Switch CI from Travis to GitHub Actions.
* Simplify benchmarks
  - All the 3rd-party gems used for comparison are very old and use old versions of the UCD.
  - Now we test against Ruby's normalization implementation, which is actually also written in Ruby and was itself upstreamed from the original eprun by @duerst.

== 1.0.0
* Repo converted into gem.
* Added MRI 1.8 compatibility.
