output "bastion_host_public_ip" {  
  value = "${aws_eip.bastion_elastic_ip.public_ip}"
}

output "bastion_host_private_ip" {  
  value = "${aws_instance.bastion_host.private_ip}"
}

output "api_server_public_ip" {  
  value = "${aws_eip.api_elastic_ip.public_ip}"
}

output "api_server_private_ip" {  
  value = "${aws_instance.api_server.private_ip}"
}

output "inference_server_public_ip" {  
  value = "${aws_eip.inference_elastic_ip.public_ip}"
}

output "inference_server_private_ip" {  
  value = "${aws_instance.inference_server.private_ip}"
}






# We save our wordpress and bastion host public ip in a file.
resource "local_file" "ip_addresses" {
  content = <<EOF
            Bastion host public ip address: ${aws_eip.bastion_elastic_ip.public_ip}
            Bastion host private ip address: ${aws_instance.bastion_host.private_ip}
            EOF
  filename = "${var.key_path}ip_addresses.txt"
}
