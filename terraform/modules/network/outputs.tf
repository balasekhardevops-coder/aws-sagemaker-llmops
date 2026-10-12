output "vpc_id" { value = aws_vpc.this.id }
output "vpc_cidr" { value = aws_vpc.this.cidr_block }
output "private_subnet_ids" {
  value = [for k in sort(keys(aws_subnet.private)) : aws_subnet.private[k].id]
}
output "private_route_table_ids" {
  value = [for k in sort(keys(aws_route_table.private)) : aws_route_table.private[k].id]
}
