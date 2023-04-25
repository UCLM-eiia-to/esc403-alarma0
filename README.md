# Generación automática de FSM

Este repositorio es un ejemplo de uso de la generación automática de código C++ a partir de máquinas de estado especificadas con [Ptolemy II](https://ptolemy.berkeley.edu/ptolemyII/index.htm).

Se utiliza una serie de convenios para dirigir la generación automática. Así, por ejemplo, es posible indicar si una entrada o salida corresponde a un pin digital y en ese caso realiza *debouncing* automático.

## Estructura del ejemplo

El proyecto es un esqueleto de la práctica de la asignatura para el curso 2022/2023. La estructura es la siguiente:

```
├── CMakeLists.txt
├── model
│   ├── timer.xml
│   └── ...
├── main
│   ├── CMakeLists.txt
│   ├── fsm.hh                Implementación genérica de máquinas de estado en C++
│   ├── fsm.cc                Implementación genérica de máquinas de estado en C++
│   └── main.cc               Ejemplo de programa principal
├── script
│   ├── pt2cpp.py             Transforma XML de Ptolemy II en C++
│   └── pt2cpp.xsl            Transformaciones XSL utilizada por el script anterior
└── README.md                 Este archivo
```

El archivo `CMakeLists.txt` de la carpeta principal contiene instrucciones para generar automáticamente el código C++ para todas las máquinas guardadas en la carpeta `model`.  Aunque solo se muestra como ejemplo `timer.xml` este proyecto está diseñado para tres máquinas de estado, que deberían encontrarse en la carpeta `model`:

* `timer.xml` es una máquina de estado con una única entrada GPIO `boton` y dos salidas `timeout1s` y `timeout10s`.  Activa la salida `timeout1s` cuando pasan `TO1S` iteraciones de la máquina de estados sin que se active el `boton`. Activa la salida `timeout10s` cuando pasan `TO10S` iteraciones de la máquina de estados sin que se active el `boton`.
* `codigo.xml` es una máquina de estados con tres entradas, una entrada GPIO `boton`, y dos entradas `timeout1s` y `timeout10s`.  Solo tiene una salida `codigo_correcto`, que se activa cuando el usuario introduce el código correcto con el método que indica el enunciado de la práctica.
* `alarma.xml` es una máquina de estados 

## Troubleshooting

* Program upload failure

    * Hardware connection is not correct: run `idf.py -p PORT monitor`, and reboot your board to see if there are any output logs.
    * The baud rate for downloading is too high: lower your baud rate in the `menuconfig` menu, and try again.

## Technical support and feedback

Please use the following feedback channels:

* For technical queries, go to the [esp32.com](https://esp32.com/) forum
* For a feature request or bug report, create a [GitHub issue](https://github.com/espressif/esp-idf/issues)

We will get back to you as soon as possible.
