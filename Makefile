_: rebuild-test

rebuild:
	sudo nixos-rebuild switch

rebuild-test:
	sudo nixos-rebuild test
	@echo "Ran rebuild without switch, make sure to run switch if needed!"

deploy:
	colmena apply --on ${target}

deploy-flake:
	nixos-rebuild switch --sudo --flake  .#${target} --target-host deploy_user@${target-host}