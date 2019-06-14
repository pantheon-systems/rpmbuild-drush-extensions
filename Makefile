
all: clean rpm

test:
	tests/confirm-rpm.sh

deps:
	gem install fpm

deps-macos:
	gem install --no-ri --no-rdoc fpm
	brew install rpm

# Add php 5.6 and Composer into our container
deps-f22:
	yum install -y php
	yum install -y composer
	echo 'memory_limit=-1' > /etc/php.ini

deps-circle:
	sudo apt-get -y install rpm
	gem install package_cloud

rpm:
	bash scripts/build-rpm.sh

clean:
	rm -rf build*
	rm -rf pkgs

.PHONY: all
