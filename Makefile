

all:
	@echo "base directory = /opt/music"
	@echo "make install/uninstall"
	@echo "configure in $BASE/etc/music.conf"


clean: uninstall

install:
	@./install.sh | tee /tmp/music_install.log
	@echo ""
	@echo "Consult /tmp/music_install.log if you need to check anything"
	@echo ""


uninstall:
	@./uninstall.sh

remove: uninstall

del: uninstall


