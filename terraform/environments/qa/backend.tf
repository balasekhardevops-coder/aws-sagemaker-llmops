terraform {
  backend "s3" {
    # The workflow provides the bucket, its region, and an environment/region-specific key.
    # Do not set defaults that could accidentally target the wrong remote state.
    encrypt      = true
    use_lockfile = true
  }
}
