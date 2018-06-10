#!/bin/bash

#Init vars
vip_app1=10.10.99.1
export no_proxy="localhost,127.0.0.1,.cisco.com,.uktme.cisco.com,10.52.249.199,192.168.81.50"

#Deploy tenant
echo "Onboarding new tenant"
ansible-playbook init_tenant.yml

read -p "Continue with Application Network Deployment?" ans
case ${ans} in
  [n]|[no]) exit 0;;
  *);;
esac

#Deploy ACI constructs
ansible-playbook aci.yml

#Get HAProxy IP from terraform.tfvars
declare -a arr
while IFS='' read line; do
  arr+=("${line}");
done < terraform.tfvars

haproxy=$(echo ${arr[-1]} | cut -d "=" -f2 | sed -e 's/[\s|"]//g')

#Deploy frontend and backend VMs and app
read -p "Continue with App and Infra resources deployment with terraform?" ans
case ${ans} in
  [n]|[no]) exit 0;;
  *);;
esac

terraform apply -auto-approve

#Generate ansible_vars.json to configure HAProxy
declare -a arr_frontend
readarray -t arr_frontend <<< "$(terraform output frontend_ips |  sed -re 's/,//g')"

cat <<EOF > ansible_vars.json
{
  "vip_app1": "${vip_app1}",
  "my_app": "polling_app",
  "webservers": [
     { "name": "webserver1", "ip": "${arr_frontend[0]}" },
     { "name": "webserver2", "ip": "${arr_frontend[1]}" },
     { "name": "webserver3", "ip": "${arr_frontend[2]}" },
     { "name": "webserver4", "ip": "${arr_frontend[3]}" }
   ],
  "frontend_port": "3000"
}
EOF

ansible-playbook -i ${haproxy}, --extra-vars "@ansible_vars.json" haproxy.yml

#Ask to remove provisioning related contracts and epgs
read -p "Remove provisioning resources?(Be sure that app has fully started)" ans
case ${ans} in
  [n]|[no]) exit 0;;
  *);;
esac
ansible-playbook remove_mgmt_prov_ctrct.yml



