## AWS Terraform 

script aws configuration

### TF version

v0.14.0 applied

* lock file enabled `.terraform.lock.hcl`
* sensitive output enabled, can only be accessed from state file

Keep in mind to change the terraform workspace to the same as branch.  

```
terraform workspace select ${branch_name}
```

There's no backend storage configured for terraform.  
This repo worked like some kind of backend of status file.  
So do remember to commit your new status to specific branch.



### dependence

most of modules which licensed as Apache2 comes from [cloudposse](https://registry.terraform.io/modules/cloudposse).
