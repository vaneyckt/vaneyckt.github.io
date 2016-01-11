+++
date = "2014-10-29T17:36:12+00:00"
title = "Creating an EC2 Instance in a VPC with the AWS CLI"
type = "post"
ogtype = "article"
topics = [ "aws" ]
+++

Setting up an EC2 instance on AWS used to be as straightforward as provisioning a machine and SSHing into it. However, this process has become a bit more complicated now that Amazon VPC has become the standard for managing machines in the cloud.

So what exactly is a Virtual Private Cloud? Amazon defines a VPC as 'a logically isolated section of the AWS Cloud'. Instances inside a VPC can by default only communicate with other instances in the same VPC and are therefore invisible to the rest of the internet. This means they will not accept SSH connections coming from your computer, nor will they respond to any http requests. In this article we'll look into changing these default settings into something more befitting a general purpose server.

### Setting up your VPC

Start by installing the [AWS Command Line Interface](http://aws.amazon.com/cli) on your machine if you haven't done so already. With this done, we can now create our VPC.

```bash
$ vpcId=`aws ec2 create-vpc --cidr-block 10.0.0.0/28 --query 'Vpc.VpcId' --output text`
```

There are several interesting things here:

- the `--cidr-block` parameter specifies a /28 netmask that allows for 16 IP addresses. This is the smallest supported netmask.
- the `create-vpc` command returns a JSON string. We can filter out specific fields from this string by using the `--query` and `--output` parameters.

The next step is to overwrite the default VPC DNS settings. As mentioned earlier, instances launched inside a VPC are invisible to the rest of the internet by default. AWS therefore does not bother assigning them a public DNS name. Luckily this can be changed easily.

```bash
$ aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-support "{\"Value\":true}"
$ aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-hostnames "{\"Value\":true}"
```

### Adding an Internet Gateway

Next we need to connect our VPC to the rest of the internet by attaching an internet gateway. Our VPC would be isolated from the internet without this.

```bash
$ internetGatewayId=`aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text`
$ aws ec2 attach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpcId
```

### Creating a Subnet

A VPC can have multiple subnets. Since our use case only requires one, we can reuse the cidr-block specified during VPC creation so as to get a single subnet that spans the entire VPC address space.

```bash
$ subnetId=`aws ec2 create-subnet --vpc-id $vpcId --cidr-block 10.0.0.0/28 --query 'Subnet.SubnetId' --output text`
```

While this `--cidr-block` parameter specifies a subnet that can contain 16 IP addresses (10.0.0.1 - 10.0.0.16), AWS will reserve 5 of those for private use. While this doesn't really have an impact on our use case, it is still good to be aware of such things.

### Configuring the Route Table

Each subnet needs to have a route table associated with it to specify the routing of its outbound traffic. By default every subnet inherits the default VPC route table which allows for intra-VPC communication only.

Here we add a route table to our subnet so as to allow traffic not meant for an instance inside the VPC to be routed to the internet through the internet gateway we created earlier.

```bash
$ routeTableId=`aws ec2 create-route-table --vpc-id $vpcId --query 'RouteTable.RouteTableId' --output text`
$ aws ec2 associate-route-table --route-table-id $routeTableId --subnet-id $subnetId
$ aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 0.0.0.0/0 --gateway-id $internetGatewayId
```

### Adding a Security Group

Before we can launch an instance, we first need to create a security group that specifies which ports should allow traffic. For now we'll just allow anyone to try and make an SSH connection by opening port 22 to any IP address.

```bash
$ securityGroupId=`aws ec2 create-security-group --group-name my-security-group --description "my-security-group" --vpc-id $vpcId --query 'GroupId' --output text`
$ aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 22 --cidr 0.0.0.0/0
```

### Launching your Instance

All that's left to do is to create an SSH key pair and then launch an instance secured by this. Let's generate this key pair and store it locally with the correct permissions.

```bash
$ aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > ~/.ssh/my-key.pem
$ chmod 400 ~/.ssh/my-key.pem
```

We can now launch a single t2.micro instance based on the public AWS Ubuntu image.

```bash
$ instanceId=`aws ec2 run-instances --image-id ami-9eaa1cf6 --count 1 --instance-type t2.micro --key-name my-key --security-group-ids $securityGroupId --subnet-id $subnetId --associate-public-ip-address --query 'Instances[0].InstanceId' --output text`
```

After a few minutes your instance should be up and running. You should now be able to obtain the url of your active instance and SSH into it.

```bash
$ instanceUrl=`aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].PublicDnsName' --output text`
$ ssh -i ~/.ssh/my-key.pem ubuntu@$instanceUrl
```

And that's it. It's really not all that hard. There's just an awful lot of concepts that you need to get your head around which can make it a bit daunting at first. Be sure to check out the free [Amazon Virtual Private Cloud User Guide](http://www.amazon.com/gp/product/B007S33NT2/ref=cm_cr_ryp_prd_ttl_sol_0) if you want to learn more about VPCs.
