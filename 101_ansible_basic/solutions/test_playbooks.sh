#!/bin/bash -xe

# step4
ansible-playbook first_playbook.yml

# step5
ansible-playbook vars_debug_playbook.yml
ansible-playbook vars_host_group_playbook.yml
ansible-playbook vars_play_playbook.yml
ansible-playbook vars_register_playbook.yml
ansible-playbook vars_task_playbook.yml

# step6
ansible-playbook loop_playbook.yml
ansible-playbook when_playbook.yml
ansible node1 -m ansible.builtin.fetch -a 'src=/etc/httpd/conf/httpd.conf dest=files/httpd.conf flat=yes'
ansible-playbook handler_playbook.yml

# step7
ansible-playbook block_playbook.yml -e 'exec_block=yes'
ansible-playbook block_playbook.yml -e 'exec_block=no'
ansible-playbook rescue_playbook.yml -e 'error_flag=no'

# step8
ansible-playbook template_playbook.yml -e 'LANG=JP'
ansible-playbook template_playbook.yml -e 'LANG=EN'

# step9
ansible node1 -m ansible.builtin.fetch -a 'src=/etc/httpd/conf/httpd.conf dest=roles/web_setup/files/httpd.conf flat=yes'
ansible-playbook role_playbook.yml

# step10
ansible-galaxy role install -r roles/requirements.yml
ansible-playbook galaxy_playbook.yml

# step11
ansible-galaxy collection install oracle.oci
ansible-galaxy collection install -r collections/requirements.yml
ansible-playbook collection_playbook.yml

# step12
ansible-playbook reporting_playbook.yml
ansible-playbook testing_assert_playbook.yml

# step50
ansible-playbook lb_web.yml
curl node4
curl node5
curl node6
curl node6
curl node6
curl node6
