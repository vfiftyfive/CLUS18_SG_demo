#!/bin/bash

#Init vars
vip_app2=10.10.99.2
export no_proxy="localhost,127.0.0.1,.cisco.com,.uktme.cisco.com,10.52.249.199,192.168.81.50"

#Deploy ACI constructs
echo "Deploying ACI constucts"
ansible-playbook aci.yml

#Get HAProxy IP from terraform.tfvars
declare -a arr
while IFS='' read line; do
  arr+=("${line}");
done < terraform.tfvars

haproxy=$(echo ${arr[-1]} | cut -d "=" -f2 | sed -e 's/[\s|"]//g')

#Deploy infra and VMs resources
read -p "Continue with App and Infra resources deployment with terraform?" ans
case ${ans} in
  [n]|[no]) exit 0;;
  *);;
esac

terraform apply -auto-approve

#Generate ansible_vars.json to configure HAProxy
declare -a arr_vms
readarray -t arr_vms <<< "$(terraform output vm_ips |  sed -re 's/,//g')"

cat <<EOF > ansible_vars.json
{
  "vip_app2": "${vip_app2}",
  "my_app": "docker_hello_world",
  "webservers": [
     { "name": "docker1", "ip": "${arr_vms[0]}" },
     { "name": "docker2", "ip": "${arr_vms[1]}" },
     { "name": "docker3", "ip": "${arr_vms[2]}" },
     { "name": "docker4", "ip": "${arr_vms[3]}" }
   ],
  "frontend_port": "80"
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



