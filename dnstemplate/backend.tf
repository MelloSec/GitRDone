terraform {
  backend "s3" {
    bucket         = "<<<BUCKET>>>"
    key            = "<<<BUCKETKEY>>>\terraform.tfstate"
    region         = "<<<BUCKETREGION>>>"
    endpoint       = "<<<BUCKETENDPOINT>>>.digitaloceanspaces.com"  
    # access_key = ""
    # secret_key = ""
    skip_credentials_validation = true
    skip_metadata_api_check = true    
  }
}