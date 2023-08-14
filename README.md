# Sistema básico de gestión de citas creado con bash

Este es un pequeño script de bash con el que crear y administrar citas. Podremos añadir el nombre de usuario, la hora de inicio de la cita y la hora de fin. También podremos listar las citas (ordenadas por nombre o por hora de inicio). También podremos eliminar la cita según el nombre que tenga asignada. Todo esto se hará desde la terminal, utilizando comandos.

![ayuda-citas-sh](https://github.com/sapoclay/gestion-citas-bash/assets/6242827/4ccf949a-bc76-4048-b399-5f1b4f041913)

El script se basa en el lenguaje de programación de shell Bash y utiliza diversas funciones y comandos para llevar a cabo las tareas de administración de citas. A continuación, desglosaré las partes clave del código:

    Declaración de Colores:

En el inicio del script, se definen códigos de escape ANSI para colores y estilos de texto que se utilizan para resaltar información en la terminal. Estos códigos permiten resaltar mensajes importantes con colores como verde, rojo y amarillo para mejorar la legibilidad y el impacto visual.

    Función show_help:

Esta función muestra la ayuda cuando se utiliza la opción -h o --help. Imprime información detallada sobre cómo usar el script y las diferentes opciones disponibles.

    Funciones de Validación de Hora:

Las funciones validar_hora verifican si el formato de hora proporcionado es válido (HH:MM) y si está dentro del rango de 00:00 a 23:59. Se utilizan expresiones regulares para realizar estas validaciones.

    Función cabecera:

La función cabecera imprime una línea de encabezado resaltada con el color verde para separar y marcar las diferentes secciones del script.

    Función add_cita:

Esta función se encarga de agregar citas. Realiza varias validaciones, como verificar si se proporcionaron suficientes argumentos, si las horas están en el formato correcto y si hay solapamiento con citas existentes. Luego, agrega la cita al archivo citas.txt si todas las condiciones se cumplen.

    Función eliminar_cita:

Esta función permite eliminar citas de un paciente específico. Busca el nombre del paciente en el archivo citas.txt, muestra detalles de la cita y solicita confirmación antes de realizar la eliminación.

    Función buscar_por_nombre:

La función busca citas que coincidan con un nombre de paciente proporcionado y muestra los resultados en la terminal. Utiliza el comando grep para buscar en el archivo citas.txt.

    Funciones buscar_por_hora_inicio y buscar_por_hora_finalizacion:

Estas funciones buscan citas que comiencen o terminen en una hora específica proporcionada. Realizan validaciones de formato y utilizan el comando grep para buscar coincidencias en el archivo citas.txt.

    Funciones listar_por_nombre y listar_por_hora:

Estas funciones muestran las citas almacenadas en el archivo citas.txt, ordenadas por nombre o por hora de inicio, respectivamente. Utilizan el comando sort para ordenar las citas antes de mostrarlas.

    Bucle case para Manejar Opciones:

El script utiliza un bucle case para manejar las diferentes opciones proporcionadas en la línea de comandos. Dependiendo de la opción elegida (como -a, -d, -s, etc.), se llama a la función correspondiente para realizar la acción requerida.

En resumen, el script Bash utiliza una combinación de comandos de terminal, expresiones regulares y funciones personalizadas para administrar citas médicas de manera efectiva. Las funciones de validación, búsqueda y manipulación de archivos son fundamentales para lograr la funcionalidad del script y proporcionar una interfaz de usuario interactiva para la gestión de citas médicas.
