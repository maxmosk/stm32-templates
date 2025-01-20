#include <stm32f1xx_ll_bus.h>
#include <stm32f1xx_ll_gpio.h>
#include <stm32f1xx_ll_rcc.h>
#include <stm32f1xx_ll_system.h>
#include <stm32f1xx_ll_usart.h>

#define NANOPRINTF_IMPLEMENTATION
#include "nanoprintf.h"

static void uart_putc(int ch, void *ctx)
{
    LL_USART_TransmitData8(USART3, ch);
    while (!LL_USART_IsActiveFlag_TXE(USART3))
        LL_mDelay(1);

    if ('\n' == ch)
    {
        uart_putc('\r', ctx);
    }
}

static void SystemClockInit(void)
{
    LL_FLASH_SetLatency(LL_FLASH_LATENCY_2);

    LL_RCC_HSE_Enable();
    while(!LL_RCC_HSE_IsReady())
        ;

    LL_RCC_PLL_ConfigDomain_SYS(LL_RCC_PLLSOURCE_HSE_DIV_1, LL_RCC_PLL_MUL_9);

    LL_RCC_PLL_Enable();
    while(!LL_RCC_PLL_IsReady())
        ;

    LL_RCC_SetAHBPrescaler(LL_RCC_SYSCLK_DIV_1);
    LL_RCC_SetSysClkSource(LL_RCC_SYS_CLKSOURCE_PLL);
    while(LL_RCC_GetSysClkSource() != LL_RCC_SYS_CLKSOURCE_STATUS_PLL)
        ;

    LL_RCC_SetAPB1Prescaler(LL_RCC_APB1_DIV_2);
    LL_RCC_SetAPB2Prescaler(LL_RCC_APB2_DIV_1);

    LL_Init1msTick(72000000);
    LL_SetSystemCoreClock(72000000);
}

static void DebugSerialInit(void)
{
    LL_GPIO_InitTypeDef GPIO_InitStruct;
    LL_USART_InitTypeDef USART_InitStruct;

    LL_APB2_GRP1_EnableClock(LL_APB2_GRP1_PERIPH_GPIOB);
    LL_APB1_GRP1_EnableClock(LL_APB1_GRP1_PERIPH_USART3);

    GPIO_InitStruct.Pin = LL_GPIO_PIN_10;
    GPIO_InitStruct.Mode = LL_GPIO_MODE_ALTERNATE;
    GPIO_InitStruct.Speed = LL_GPIO_SPEED_FREQ_HIGH;
    GPIO_InitStruct.OutputType = LL_GPIO_OUTPUT_PUSHPULL;
    LL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = LL_GPIO_PIN_11;
    GPIO_InitStruct.Mode = LL_GPIO_MODE_FLOATING;
    LL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    USART_InitStruct.BaudRate = 9600;
    USART_InitStruct.DataWidth = LL_USART_DATAWIDTH_8B;
    USART_InitStruct.StopBits = LL_USART_STOPBITS_1;
    USART_InitStruct.Parity = LL_USART_PARITY_NONE;
    USART_InitStruct.TransferDirection = LL_USART_DIRECTION_TX_RX;
    USART_InitStruct.HardwareFlowControl = LL_USART_HWCONTROL_NONE;

    LL_USART_DisableDMAReq_TX(USART3);
    LL_USART_DisableDMAReq_RX(USART3);

    LL_USART_Init(USART3, &USART_InitStruct);
    LL_USART_ConfigAsyncMode(USART3);
    LL_USART_Enable(USART3);
}

int main(void)
{
    SystemClockInit();
    DebugSerialInit();

    while (1)
    {
        npf_pprintf(uart_putc, NULL, "Hello, World!\n");
        LL_mDelay(10000);
    }
    return 0;
}
