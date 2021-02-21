terraform {
  backend "s3" {
    bucket = "l2l-eu-west-2-tfstate"
    key    = "eu-west-2/l2l/terraform/tf.state"
    region = "eu-west-2"
  }
}
