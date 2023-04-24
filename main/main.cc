#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "timer.hh"
#include "codigo.hh"
#include "alarma.hh"

extern "C" void app_main();
void app_main(void)
{
    // máquina para generar timeouts
    timer t;
    // máquina para comprobar código, conectada a timeouts
    codigo c{t.timeout1s, t.timeout10s, 759};
    // máquina de alarma, conectada a máquina de código
    alarma a{c.codigo_correcto};
    // composición síncrona de las tres máquinas
    fsm_composite fsm{t,c,a};
    
    TickType_t last = xTaskGetTickCount();
    for(;;) {
        fsm.iteration();
        xTaskDelayUntil(&last, 200/portTICK_PERIOD_MS); // periodo 200ms
    }
}
