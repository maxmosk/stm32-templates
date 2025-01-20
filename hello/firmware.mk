SOURCES_C_USER += $(PROJECT_DIR)/main.c
SOURCES_C_USER += $(PERIPH_PREFIX)stm32f1xx_ll_usart.c $(PERIPH_PREFIX)stm32f1xx_ll_gpio.c
SOURCES_C_USER += $(PERIPH_PREFIX)stm32f1xx_ll_utils.c $(PERIPH_PREFIX)stm32f1xx_ll_rcc.c

include $(ROOT_DIR)/lib/nanoprintf/lib.mk
