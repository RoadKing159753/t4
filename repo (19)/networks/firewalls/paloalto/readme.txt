Palo Alto Ansible Deployment

Install Requirements:

$ cd /networks/firewalls/paloalto
$ sudo yum install ansible
$ sudo yum install python-pip
$ ansible-galaxy collection install -r collections/requirements.yml
$ pip3 install -r requirements.txt

Palo Alto configuration playbooks:

1. When running a playbook you will first be prompted for the ansible-vault password, this will decrypt the password
   and API Key variables (These are encrypted with AES256 via Ansible Vault). Using the "-e" option we will specify the variable "target":
   target=test - Test Network Palo Alto's
   target=northampton - Northampton Palo Alto's
   target=wakefield - Wakefield Palo Alto's

2. Confirm the host system settings in host_vars/ for the device you want to configure:
	• pa_bwptest.yml
	• pa_northampton.yml
	• pa_wakefield.yml

3. Confirm the objects / groups and firewall rules in 'configuration/objects/' for the 
   device you want to configure:
	• test
	• northampton
	• wakefield

4. Once all settings are verified run the required configuration playbook:
	• pa_deviceconfig.yml - system settings / interfaces / zones / routing
	• pa_objects.yml - objects / object-groups / services / service-groups
	• pa_rules.yml - firewall rules
    • pa_full_config.yml - all of the above

	Automatic commit has been disabled, ensure the configuration is on the device and perform a manual commit

    usage: ansible-playbook configuration/pa_full_config.yml -e "target=test"




Full Config Playbook runtime from testing the Test Palo configuration:

Playbook run took 0 days, 0 hours, 48 minutes, 0 seconds
Tuesday 13 September 2022  16:53:19 +0100 (0:09:04.691)       0:48:00.024 ***** 
=============================================================================== 
Create firewall objects ------------------------------------------------------------------------- 1483.03s
Create security rules --------------------------------------------------------------------------- 544.69s
Create service objects -------------------------------------------------------------------------- 489.15s
Create address groups --------------------------------------------------------------------------- 113.41s
Re running task for nested groups --------------------------------------------------------------- 90.20s
Create service group objects -------------------------------------------------------------------- 50.28s
Re running task for nested groups --------------------------------------------------------------- 41.24s
Configure interfaces ---------------------------------------------------------------------------- 34.32s
Configure static routes ------------------------------------------------------------------------- 12.94s
Configure firewall zones ------------------------------------------------------------------------ 7.78s
Set device local settings ----------------------------------------------------------------------- 6.30s
Configure virtual router ------------------------------------------------------------------------ 4.22s
Gathering Facts --------------------------------------------------------------------------------- 2.19s
include_vars ------------------------------------------------------------------------------------ 0.25s
