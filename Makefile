
all: clean rpm

test: deps
	tests/confirm-rpm.sh

deps:
	gem install fpm

deps-macos:
	sudo gem install --no-ri --no-rdoc fpm

deps-circle:
	sudo apt-get -y install rpm
	gem install package_cloud

rpm:
	bash scripts/build-rpm.sh

clean:
	rm -rf build*
	rm -rf pkgs

.PHONY: all
