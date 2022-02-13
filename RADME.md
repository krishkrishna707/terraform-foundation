# terraform-aws instance key pair and file details 
#BEFORE WRITE THE TERRAFORM CODE FILE SHOULD BE .TF EXTENTION 



#provider.tf 
      provider "aws" {
         region = "us-east-1"
         version = "~> 3.0"
      }
#In this file we mention the cloud platform eg: aws
#In this file file we can able to mention the version 

#resource.tf
      resource "aws_key_pair" "deployer" {
          key_name   = "deployer-key"
          public_key = ""
      }    

#In this resource file only we can mention the aws seervice name (module name) and second name is the unique name for each aws resoure (callable name)


#variable.tf
    variable "REGION" {
        default = "us-east-1"
    }
    variable "KEY_NAME" {
        default = "test"
    }
    variable "PUBLIC_KEY" {
        default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6t"
    }  

#In this file we mention the variable and store value of variable in default 
