terraform {
  backend "s3" {
    bucket = "terraform"
    key    = "terraform.tfstate"
    region = "us-east-1" 

    use_path_style = true
    use_lockfile   = true
    insecure       = true # Incus serves S3 with its self-signed server cert

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}
