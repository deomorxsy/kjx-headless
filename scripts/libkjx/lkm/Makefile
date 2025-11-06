# LKM
#
obj-m += hello-1.o

#LKM_PWD := $(CURDIR)/scripts/libkjx/lkm_idk

all:
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean


