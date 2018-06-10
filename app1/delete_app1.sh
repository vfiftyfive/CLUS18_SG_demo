#!/bin/bash

export no_proxy=$no_proxy,10.52.249.199
declare -a arr
while IFS='' read line; do
  arr+=("${line}");
done < terraform.tfvars

haproxy=$(echo ${arr[-1]} | cut -d "=" -f2 | sed -e 's/[\s|"]//g')

terraform destroy -auto-approve && ansible-playbook -i ${haproxy}, --extra-vars "@ansible_vars.json" delete_app1.yml
