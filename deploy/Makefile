decrypt:
	find group_vars/ -name 'secret.yml' -exec ansible-vault decrypt '{}' ';'

encrypt:
	find group_vars/ -name 'secret.yml' -exec ansible-vault encrypt '{}' ';'

deploy:
	ansible-playbook -i hosts.ini -l bot-prod -t deploy -u apps site.yml
