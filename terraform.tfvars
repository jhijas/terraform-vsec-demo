# Adjust vars for the AWS settings and region
# These VPCs, subnets, and gateways will be created as part of the demo
public_key_path = "~/.ssh/id_rsa.pub"
aws_region = "eu-west-1"
key_name = "AWS-SSH-terraform"
aws_vpc_cidr = "10.20.0.0/16"
aws_external_subnet_cidr = "10.20.0.0/24"
aws_webserver_subnet_cidr = "10.20.10.0/24"
aws_database_subnet_cidr = "10.20.11.0/24"
aws_lb1_subnet_cidr = "10.20.5.0/24"
aws_lb2_subnet_cidr = "10.20.6.0/24"
perimeter_gw_external_ip = "10.20.0.10"
perimeter_gw_internal_ip = "10.20.1.10"
aws_internal_route = "10.20.1.1"
r53zone = "cloudprotection.eu"
externaldnshost = "siac-demo"

my_user_data = <<-EOF
                #!/bin/bash
                clish -c 'set user admin shell /bin/bash' -s
                clish -c 'set static-route {{ aws_lb1_subnet_cidr }} nexthop gateway address {{ aws_internal_route }} on' -s
                clish -c 'set static-route {{ aws_lb2_subnet_cidr }} nexthop gateway address {{ aws_internal_route }} on' -s
                clish -c 'set static-route {{ aws_webserver_subnet_cidr }} nexthop gateway address {{ aws_internal_route }} on' -s
                clish -c 'set static-route {{ aws_database_subnet_cidr }} nexthop gateway address {{ aws_internal_route }} on' -s
                config_system -s 'install_security_gw=true&install_ppak=true&gateway_cluster_member=false&install_security_managment=false&ftw_sic_key=vpn12345';shutdown -r now;
                EOF
ubuntu_user_data = <<-EOF
                    #!/bin/bash
                    until sudo apt-get update && sudo apt-get -y install apache2;do
                      sleep 1
                    done
                    until sudo curl \
                      --output /var/www/html/vsec.jpg \
                      --url https://s3-us-west-2.amazonaws.com/azure.templates/testdrive/vsec.jpg ; do
                       sleep 1
                    done
                    sudo chmod a+w /var/www/html/index.html 
                    echo "<html><head><meta http-equiv=refresh content=2;'http://siac-demo.cloudprotection.eu/' /> </head><body><H1>" > /var/www/html/index.html
                    echo $HOSTNAME >> /var/www/html/index.html
                    echo "<BR><BR>Hello World - Check Point vSEC IaC Demo <BR><BR>" >> /var/www/html/index.html
                    echo "<img src=\"/vsec.jpg\" height=\"25%\">" >> /var/www/html/index.html
                    EOF
