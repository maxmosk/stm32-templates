NANOPRINTF_DIR = nanoprintf

USER_DIRS += $(NANOPRINTF_DIR)
CFLAGS_USER += -I$(NANOPRINTF_DIR)

$(NANOPRINTF_DIR):
	git clone https://github.com/charlesnicholson/nanoprintf.git $@
