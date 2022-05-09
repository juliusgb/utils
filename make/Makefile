.PHONY: default-start

default-start:
    ifeq ($(OS),Windows_NT)
		$(MAKE) -f Makefile-Windows
    else
		$(MAKE) init
    endif

init:
    ifeq ($(var),foo)
		@echo $(var) "bar"
    else
		@echo "others"
    endif
