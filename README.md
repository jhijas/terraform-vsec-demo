# Two-Tier AWS Secure Architecture demo

Demo code for provisioning a two-tier architectue consisting on a loadblanced autoscale group of Check Point security gateways and a loadbalanced autoscale group of web servers

This example will create a new EC2 Key Pair in the specified AWS Region. The key name and path to the public key must be specified via the terraform variables file.

Finally the code will register the external LB IP address into a route53 existing zone. 

After you run `terraform apply` on this configuration, it will
automatically output the DNS address of URL registered according to the variables defined in the variables.tfvars file. 

This architecture relies on an existing Check Point management server where autoregistration is already configured to monitor the same AWS subscription. 

After your instances are registered, the resgired DNS record will respond with a demo web page.

To run, configure your AWS provider as described in 

https://www.terraform.io/docs/providers/aws/index.html

Also make sure you edit the terraform.tfvars file to include your key and any other parameter you want to customize for your environment.

Run with a command like this:

```
terraform apply 
```

