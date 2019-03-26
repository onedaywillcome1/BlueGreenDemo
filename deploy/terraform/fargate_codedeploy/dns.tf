data "aws_route53_zone" "alb_domain" {
  name         = "${var.domain_name}"
  private_zone = false
}

data "aws_elb_hosted_zone_id" "alb_zone" {}

resource "aws_route53_record" "alb_domain_record" {
  zone_id = "${data.aws_route53_zone.alb_domain.zone_id}"
  name    = "${lower(var.domain_prefix)}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = "${var.alb_dns_name}"
    zone_id                = "${data.aws_elb_hosted_zone_id.alb_zone.id}"
    evaluate_target_health = false
  }
}