variable "region" {
  default = "ap-southeast-2"
}

provider "aws" {
  region = "${var.region}"
}

module "memebot" {
  source      = "slash_command"
  name        = "memebot"
  region      = "${var.region}"
  source_code = "memebot.zip"
}

output "command_url" {
  value = "${module.memebot.command_url}"
}
