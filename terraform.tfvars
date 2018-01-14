# Adjust vars for the AWS settings and region
# These VPCs, subnets, and gateways will be created as part of the demo
public_key_path = "~/.ssh/id_rsa.pub"
aws_region = "eu-west-1"
key_name = "AWS-SSH-terraform"
aws_vpc_cidr = "10.20.0.0/16"
aws_external1_subnet_cidr = "10.20.1.0/24"
aws_external2_subnet_cidr = "10.20.2.0/24"
aws_webserver1_subnet_cidr = "10.20.10.0/24"
aws_webserver2_subnet_cidr = "10.20.20.0/24"
r53zone = "cloudprotection.eu"
externaldnshost = "siac-demo"

my_user_data = <<-EOF
                #!/bin/bash
                clish -c 'set user admin shell /bin/bash' -s
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
