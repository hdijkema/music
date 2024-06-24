

all:
	@echo "base directory = /opt/music"
	@echo "make install/uninstall"
	@echo "configure in $BASE/etc/music.conf"


clean: uninstall

install:
	@./install.sh 


uninstall:
	@./uninstall.sh

remove: uninstall

del: uninstall


