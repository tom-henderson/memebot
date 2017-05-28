variable "region" {
  default = "ap-southeast-2"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_sns_topic" "topic" {
  name = "meme_requests"
}

module "memebot" {
  source        = "slash_command"
  name          = "memebot"
  region        = "${var.region}"
  source_code   = "memebot.zip"
  sns_topic_arn = "${aws_sns_topic.topic.arn}"
}

module "memebot_worker" {
  source        = "worker_lambda"
  name          = "memebot_worker"
  region        = "${var.region}"
  source_code   = "memebot_worker.zip"
  sns_topic_arn = "${aws_sns_topic.topic.arn}"
}

output "command_url" {
  value = "${module.memebot.command_url}"
}
