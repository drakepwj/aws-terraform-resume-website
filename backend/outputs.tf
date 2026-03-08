output "visitor_counter_api_url" {
  value = "${aws_apigatewayv2_api.http_api.api_endpoint}/count"
}
