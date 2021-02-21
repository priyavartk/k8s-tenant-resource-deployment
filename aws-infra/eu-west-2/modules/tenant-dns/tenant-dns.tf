variable "tenant" {
  type = string
}

resource "aws_route53_zone" "tenant" {
 name = "${var.tenant}.cooldevops.uk"

 tags = {
    tenant = "${var.tenant}"
  }
}

resource "aws_route53_record" "tenant-ns" {
  zone_id = "${aws_route53_zone.cooldevops.zone_id}"
  name    = "${var.tenant}.cooldevops.uk"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.tenant.name_servers.0}",
    "${aws_route53_zone.tenant.name_servers.1}",
    "${aws_route53_zone.tenant.name_servers.2}",
    "${aws_route53_zone.tenant.name_servers.3}",
  ]
}
