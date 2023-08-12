#!/bin/bash

# Archivo para guardar los datos
ARCHIVO_CITAS="citas.txt"

# Colores
verde="\033[1;32m"
cierreVerde="\033[0m"
rojo="\033[1;31m"
cierreRojo="\033[0m"
amarillo="\033[1;33m"
cierreAmarillo="\033[0m"

# Función para mostrar el menú
mostrar_menu() {
    echo "============="
    echo -e "${verde}Menú de Citas${cierreVerde}"
    echo "============="
    echo -e "${rojo}1${cierreRojo}. Añadir nueva cita"
    echo -e "${rojo}2${cierreRojo}. Buscar cita por nombre del paciente"
    echo -e "${rojo}3${cierreRojo}. Buscar citas por hora de inicio"
    echo -e "${rojo}4${cierreRojo}. Buscar citas por hora de fin"
    echo -e "${rojo}5${cierreRojo}. Listar citas ordenadas por nombre del paciente"
    echo -e "${rojo}6${cierreRojo}. Listar citas ordenadas por hora de inicio"
    echo -e "${rojo}7${cierreRojo}. Eliminar cita por nombre del paciente"
    echo -e "${rojo}8${cierreRojo}. Visitar entreunosyceros"
    echo ""
    echo -e "${rojo}0${cierreRojo}. Salir"
    echo ""
}


# Función para mostrar la cabecera
function cabecera() {
    echo -e "${verde}==============================="
    echo "  $1"
    echo "==============================="
    echo -e "${cierreVerde}"
    echo ""
}

# Función para pausar la ejecución del programa
function pausar() {
    
    # -n 1 indica que read debe leer solo un carácter de entrada
    # -s Hace que la entrada del usuario no se muestre en la pantalla
    # -r: indica que read debe interpretar la entrada sin interpretar caracteres de escape
    # -p muestra un mensaje en la pantalla
    echo ""
    echo -e "${amarillo}"
    read -n 1 -s -r -p "Pulsa cualquier tecla para continuar..."
    echo -e "${cierreAmarillo}"
}

# Función para validar si una hora está en el rango de 00:00 a 23:59
validar_hora() {
    hora=$1
    if [[ ! $hora =~ ^([01][0-9]|2[0-3])(:[0-5][0-9])?$ ]]; then
        echo ""
        echo -e "${rojo}Error: Formato de hora incorrecto. Usa el formato HH o HH:MM (00:00 - 23:59).${cierreRojo}"
        sleep 2
        # return 1 hará que la función validar_hora devuelva un valor de salida de 1 en lugar de cerrar todo el programa
        return 1
    fi
}

agregar_cita() {
    clear
    cabecera "Añadir cita"
    echo ""
    read -p "Nombre del paciente: " nombre_paciente
    read -p "Hora de inicio (formato HH:MM): " hora_inicio
    read -p "Hora de fin (formato HH:MM): " hora_fin
    
    # Validar el formato de las horas
    validar_hora "$hora_inicio"
    if [[ $? -eq 1 ]]; then
        pausar
        return
    fi
    validar_hora "$hora_fin"
    if [[ $? -eq 1 ]]; then
        pausar
        return
    fi

    # Convertir las horas en minutos totales para comparación
    inicio_minutos=$(( 10#$(date -d "$hora_inicio" +%H) * 60 + 10#$(date -d "$hora_inicio" +%M) ))
    fin_minutos=$(( 10#$(date -d "$hora_fin" +%H) * 60 + 10#$(date -d "$hora_fin" +%M) ))

    # Verificar si la hora de inicio es anterior a la hora de fin
    if (( inicio_minutos >= fin_minutos )); then
        echo ""
        echo -e "${rojo}Error: La hora de inicio debe ser anterior a la hora de fin.${cierreRojo}"
        pausar
        return
    fi

    # Comprobar si el archivo de citas existe, si no, crearlo
    if [[ ! -e "$ARCHIVO_CITAS" ]]; then
        touch "$ARCHIVO_CITAS"
    fi

    # Comprobar si el nombre ya existe en el archivo de citas
    if grep -q "^$nombre_paciente," "$ARCHIVO_CITAS"; then
        echo ""
        echo -e "${rojo}Error: El nombre introducido ya existe en el archivo de citas.${cierreRojo}"
        pausar
        return
    fi

    # Crear un arreglo de horas ocupadas
    horas_ocupadas=()
    while IFS=',' read -r _ existente_inicio existente_fin; do
        inicio_existente_minutos=$(( 10#$(date -d "$existente_inicio" +%H) * 60 + 10#$(date -d "$existente_inicio" +%M) ))
        fin_existente_minutos=$(( 10#$(date -d "$existente_fin" +%H) * 60 + 10#$(date -d "$existente_fin" +%M) ))
        
        for (( i = inicio_existente_minutos; i < fin_existente_minutos; i++ )); do
            horas_ocupadas+=("$i")
        done
    done < "$ARCHIVO_CITAS"

    # Verificar solapamiento de horas
    for (( i = inicio_minutos; i < fin_minutos; i++ )); do
        if [[ " ${horas_ocupadas[@]} " =~ " $i " ]]; then
            echo ""
            echo -e "${rojo}Error: La cita se solapa con otra cita existente.${cierreRojo}"
            pausar
            return
        fi
    done

    # Añadir la cita al archivo
    echo "$nombre_paciente,$hora_inicio,$hora_fin" >> "$ARCHIVO_CITAS"
    echo ""
    echo -e "${verde}Cita añadida de forma correcta!${cierreVerde}"
    pausar
}

# Función para buscar cita por nombre de paciente
buscar_por_nombre() {
    clear
    cabecera "Buscar por nombre"
    echo ""
    read -p "Escribe el patrón de búsqueda para el nombre del paciente: " patron
    echo ""

    # Filtrar las líneas del archivo por el primer campo (nombre del paciente) usando awk
    resultados=$(awk -F ',' -v pattern="$patron" -v highlight="$patron" '{ gsub(highlight, "\033[1;31m&\033[0m", $1); if ($1 ~ pattern) print "Paciente: " $1 ". Hora de inicio: " $2 " - Hora de fin: " $3 }' "$ARCHIVO_CITAS")

    # Verificar si se encontraron resultados
    if [[ -z "$resultados" ]]; then
        echo ""
        echo -e "${rojo}No se han encontrado coincidencias de búsqueda.${cierreRojo}"
    else
        echo "$resultados"
    fi

    echo ""
    pausar
}

# Función para buscar citas por hora de inicio
buscar_por_inicio() {
    clear
    cabecera "Buscar por hora de inicio"
    echo ""
    read -p "Escribe la hora de inicio (formato HH:MM) para buscar citas: " hora_inicio
    validar_hora "$hora_inicio"

    # Filtrar las líneas del archivo por el segundo campo (hora de inicio) usando awk
    resultados=$(awk -F ',' -v pattern="$hora_inicio" '
        BEGIN { highlight = "\033[1;31m" pattern "\033[0m" }
        $2 == pattern {
            print "";
            gsub(pattern, highlight, $2);
            print "Paciente: " $1 ". Hora de inicio: " $2 " - Hora de fin: " $3;
        }
    ' "$ARCHIVO_CITAS")

    # Verificar si se encontraron resultados
    if [[ -z "$resultados" ]]; then
        echo -e "${rojo}No se han encontrado coincidencias de búsqueda.${cierreRojo}"
    else
        echo "$resultados"
    fi

    echo ""
    pausar
}


# Función para buscar citas por hora de fin
buscar_por_fin() {
    clear
    cabecera "Buscar por hora de fin"
    echo ""
    read -p "Escribe la hora de fin (formato HH) para buscar citas: " hora_fin
    validar_hora "$hora_fin"

    # Filtrar las líneas del archivo por el tercer campo (hora de fin) usando awk
    resultados=$(grep ",$hora_fin$" "$ARCHIVO_CITAS" | awk -F ',' -v highlight="$hora_fin" '
        {
            print "";
            gsub(highlight, "\033[1;31m&\033[0m", $3);
            print "Paciente: " $1 ". Hora de inicio: " $2 " - Hora de fin: " $3;
            found = 1; # Marcar que se encontraron resultados
        }
        END {
            if (found != 1) {
                print "No se han encontrado coincidencias de búsqueda.";
            }
        }
    ')

    echo "$resultados"
    echo ""
    pausar
}

# Función para listar citas ordenadas por nombre de paciente
listar_por_nombre() {
    clear
    cabecera "Orden alfabético"
    echo ""
    sort -t ',' -k 1 "$ARCHIVO_CITAS" | awk -F ',' '{print "- Paciente: " $1 ". Hora de inicio: " $2 " - Hora de fin: " $3}'
    pausar
}

# Función para listar citas ordenadas por hora de inicio
listar_por_inicio() {
    clear
    cabecera "Ordenadado por hora de inicio"
    echo ""
    sort -t ',' -k 2 "$ARCHIVO_CITAS" | awk -F ',' '{print "- Paciente: " $1 ". Hora de inicio: " $2 " - Hora de fin: " $3}'
    pausar
}

# Función para abrir una web en el navegador por defecto del sistema Linux
abrir_web() {
    xdg-open https://entreunosyceros.net/
}

# Función para eliminar citas por medio del nombre de usuario
eliminar_cita() {
    clear
    cabecera "Eliminar cita"
    echo ""
    read -p "Escribe el nombre del paciente cuya cita deseas eliminar: " nombre_paciente

    # Verificar si el nombre existe en el archivo de citas
    if grep -q "^$nombre_paciente," "$ARCHIVO_CITAS"; then
        echo ""
        echo -e "${rojo}"
        read -p "¿Estás seguro de que deseas eliminar la cita de $nombre_paciente? (S/N): " confirmacion
        echo -e "${cierreRojo}"

        if [[ "$confirmacion" == "S" || "$confirmacion" == "s" ]]; then
            grep -v "^$nombre_paciente," "$ARCHIVO_CITAS" > temp.txt
            # verifica si el nombre existe en el archivo citas.txt. Si existe, se crea un nuevo archivo temporal sin la línea correspondiente al nombre del paciente 
            # y se renombra a citas.txt, eliminando así la cita
            mv temp.txt "$ARCHIVO_CITAS"
            echo ""
            echo -e "${verde}Cita eliminada correctamente.${cierreVerde}"
        else
            echo ""
            echo -e "${amarillo}Eliminación cancelada.${cierreAmarillo}"
        fi
    else
        echo ""
        echo -e "${rojo}El nombre introducido no existe en el archivo de citas.${cierreRojo}"
    fi

    pausar
}

# Inicio del programa
while true; do
    clear
    mostrar_menu
    echo -e "${amarillo}"
    read -p "Selecciona una opción: " opcion
    echo -e "${cierreAmarillo}"
    case $opcion in
        0) echo ""; echo -e "${verde}¡Programa terminado! ... Saliendo${cierreVerde}"; exit 0 ;;
        1) agregar_cita ;;
        2) buscar_por_nombre ;;
        3) buscar_por_inicio ;;
        4) buscar_por_fin ;;
        5) listar_por_nombre ;;
        6) listar_por_inicio ;;
        7) eliminar_cita ;;
        8) abrir_web ;;
        *)
            # se verifica si la variable opcion no está vacía (-n "$opcion") y si no es ninguno de los números del 0 al 6. 
            # En este caso, muestra el mensaje de "Opción inválida" 
            if [[ -n "$opcion" ]]; then
                echo ""
                echo -e "${rojo} Opción inválida. Por favor, selecciona una opción válida. ${cierreRojo}"
                pausar
            fi
            ;;
    esac
done

