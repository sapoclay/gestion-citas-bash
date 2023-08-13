#!/bin/bash

# Colores
verde="\033[1;32m"
cierreVerde="\033[0m"
rojo="\033[1;31m"
cierreRojo="\033[0m"
amarillo="\033[1;33m"
cierreAmarillo="\033[0m"

# Función para mostrar la ayuda
show_help() {
    cabecera "          AYUDA"
    echo ""
    echo -e "${amarillo}Uso: citas.sh [opciones]${cierreAmarillo}"
    echo "Opciones:"
    echo "  -h, --help             Mostrar esta ayuda"
    echo "  -a, --add              Añadir una cita con HORA_INICIO, HORA_FIN y NOMBRE_PACIENTE (10:00 11:00 NombrePaciente)."
    echo "  -d, --delete           Borrar una cita de un paciente. Sin argumentos."
    echo "  -s, --search           Buscar pacientes por el nombre."
    echo "  -i, --init             Buscar pacientes que empiecen a una HORA_INICIO determinada."
    echo "  -e, --end              Buscar pacientes que terminen a una HORA_FIN determinada."
    echo "  -n, --name             Listar todas las citas ordenadas por NOMBRE_PACIENTE. Sin argumentos."
    echo "  -o, --hour             Listar todas las citas ordenadas por HORA_INICIO. Sin argumentos."
    echo ""
    exit 0
}

# Función para validar el formato de hora (HH:MM)
validar_hora() {
    if [[ "$1" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
        return 0
    else
        return 1
    fi
}

function cabecera() {
    echo -e "${verde}==============================="
    echo "  $1"
    echo "==============================="
    echo -e "${cierreVerde}"
}

# Función para añadir citas. Comprobación parámetros, existencia archivo citas.txt, formato de horas, solapamiento citas, comprobación de si ya hay una cita
# para el usuario
add_cita() { 
    cabecera "       Añadir citas"
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo -e "${rojo}Faltan parámetros. Uso: add_cita HORA_INICIO HORA_FIN NOMBRE_PACIENTE${cierreRojo}"
        exit 1
    fi

    if [ ! -e citas.txt ]; then
        touch citas.txt
        echo -e "${verde}Se ha creado la BD citas.txt${cierreVerde}"
    fi

    if ! validar_hora "$1" || ! validar_hora "$2"; then
        echo -e "${rojo}Las horas deben estar en el formato correcto (HH:MM) y en el rango de 00:00 a 23:59.${cierreRojo}"
        exit 1
    fi

    if [[ "$1" < "$2" ]]; then
        solapamiento=false
        while IFS=',' read -r inicio_existente fin_existente _; do
            # Calcula los minutos correspondientes a las horas y minutos de inicio y fin de la cita existente
            inicio_existente_minutos=$(( 10#$(date -d "$inicio_existente" +%H) * 60 + 10#$(date -d "$inicio_existente" +%M) ))
            fin_existente_minutos=$(( 10#$(date -d "$fin_existente" +%H) * 60 + 10#$(date -d "$fin_existente" +%M) ))
            
            # Calcula los minutos correspondientes a las horas y minutos de inicio y fin de la nueva cita
            nuevo_inicio_minutos=$(( 10#$(date -d "$1" +%H) * 60 + 10#$(date -d "$1" +%M) ))
            nuevo_fin_minutos=$(( 10#$(date -d "$2" +%H) * 60 + 10#$(date -d "$2" +%M) ))
            
            # Verifica si hay solapamiento entre las citas
            if (( nuevo_inicio_minutos >= inicio_existente_minutos && nuevo_inicio_minutos < fin_existente_minutos )) || \
            (( nuevo_fin_minutos > inicio_existente_minutos && nuevo_fin_minutos <= fin_existente_minutos )) || \
            (( inicio_existente_minutos >= nuevo_inicio_minutos && inicio_existente_minutos < nuevo_fin_minutos )) || \
            (( fin_existente_minutos > nuevo_inicio_minutos && fin_existente_minutos <= nuevo_fin_minutos )); then
                solapamiento=true
                break
            fi
        done < citas.txt
        
        if $solapamiento; then
            echo -e "${rojo}La cita se solapa con otra cita existente.${cierreRojo}"
        else
            if grep -q "$3" citas.txt; then
                echo -e "${rojo}Ya existe una cita para el paciente $3.${cierreRojo}"
            else
                echo "$1,$2,$3" >> citas.txt
                echo -e "${verde}Cita para $3 añadida de forma correcta. Hora de inicio: $1. Hora de fin: $2${cierreVerde}"
            fi
        fi
    else
        echo -e "${rojo}La hora de inicio debe ser anterior a la hora de fin.${cierreRojo}"
    fi
}

eliminar_cita() {
    cabecera "    Eliminar una cita"
    if [ -e citas.txt ]; then
        read -p "Escribe el nombre del paciente para eliminar su cita: " nombre_paciente
        if [ -z "$nombre_paciente" ]; then
            echo ""
            echo -e "${rojo}El nombre del paciente no puede estar vacío.${cierreRojo}"
            return
        fi

        if grep -q "$nombre_paciente" citas.txt; then
            echo ""
            echo "Se encontró una cita para el paciente $nombre_paciente:"
            grep "$nombre_paciente" citas.txt
            echo ""
            echo -e "${rojo}"
            read -p "¿Estás seguro de que quieres eliminar esta cita? (s/n): " confirmacion
            echo -e "${cierreRojo}"
            if [ "$confirmacion" = "s" ]; then
                grep -v "$nombre_paciente" citas.txt > citas_tmp.txt
                mv citas_tmp.txt citas.txt
                echo -e "${verde}Cita para el paciente $nombre_paciente eliminada.${cierreVerde}"
            else
                echo ""
                echo -e "${amarillo}Eliminación cancelada.${cierreAmarillo}"
            fi
        else
            echo ""
            echo -e "${amarillo}No se encontró ninguna cita para el paciente $nombre_paciente.${cierreAmarillo}"
        fi
    else
        echo ""
        echo -e "${rojo}El archivo citas.txt no existe. Primero añade registros de citas.${cierreRojo}"
    fi
}

buscar_por_nombre() {
    cabecera "   Búsqueda por nombre"
    if [ -z "$1" ]; then
        echo ""
        echo -e "${rojo}Falta la opción del nombre del paciente.${cierreRojo}"
    elif [ -e citas.txt ]; then
        resultados=$(grep -i ",.*$1" citas.txt)
        if [ -n "$resultados" ]; then
            echo "$resultados" | while IFS=',' read -r inicio fin paciente; do
                echo -e "-> ${verde}Paciente: $paciente ${cierreVerde}- Hora inicio: $inicio - Hora fin: $fin"
            done
        else
            echo ""
            echo -e "${amarillo}No se encontraron pacientes con el nombre '$1'.${cierreAmarillo}"
        fi
    else
        echo ""
        echo -e "${rojo}El archivo citas.txt no existe.${cierreRojo}"
    fi
}

# Función para buscar pacientes que empiecen a una hora determinada
buscar_por_hora_inicio() {
    cabecera "Búsqueda por hora de inicio"
    if [ -z "$1" ]; then
        echo -e "${rojo}Falta la opción de la hora de inicio.${cierreRojo}"
        exit 1
    elif ! validar_hora "$1"; then
        echo -e "${rojo}La hora de inicio debe estar en el formato correcto (HH:MM) y en el rango de 00:00 a 23:59.${cierreRojo}"
        exit 1
    elif [ -e citas.txt ]; then
        resultados=$(grep "^$1," citas.txt)
        if [ -n "$resultados" ]; then
            echo "Pacientes con cita que empiezan a la hora '$1':"
            echo "$resultados" | while IFS=',' read -r inicio fin paciente; do
                echo -e "-> Paciente: $paciente - ${verde}Hora inicio: $inicio ${cierreVerde}- Hora fin: $fin"
            done
        else
            echo -e "${amarillo}No se encontraron pacientes con cita que empiecen a la hora '$1'.${cierreAmarillo}"
        fi
    else
        echo -e "${rojo}El archivo citas.txt no existe.${cierreRojo}"
        exit 1
    fi
}

# Función para buscar pacientes que terminen a una hora determinada
buscar_por_hora_finalizacion() {
    cabecera "Búsqueda por hora de finalización"

    if [ -z "$1" ]; then
        echo -e "${rojo}Falta la opción de la hora de finalización.${cierreRojo}"
        exit 1
    elif ! validar_hora "$1"; then
        echo -e "${rojo}La hora de finalización debe estar en el formato correcto (HH:MM) y en el rango de 00:00 a 23:59.${cierreRojo}"
        exit 1
    fi
    
    if [ -e citas.txt ]; then
        resultados=$(grep ",$1" citas.txt)
        if [ -n "$resultados" ]; then
            echo "Pacientes con cita que terminan a la hora '$1':"
            echo "$resultados" | while IFS=',' read -r inicio fin paciente; do
                echo -e "-> Paciente: $paciente - Hora inicio: $inicio - ${verde}Hora fin: $fin ${cierreVerde}"
            done
        else
            echo -e "${rojo}No se encontraron pacientes con cita que terminen a la hora '$1'.${cierreRojo}"
        fi
    else
        echo -e "${rojo}El archivo citas.txt no existe.${cierreRojo}"
        exit 1
    fi
}

# Función para listar citas ordenadas por nombre
listar_por_nombre() {
    cabecera "Listado ordenado por nombre"
    # -k3 ordena vía key posición3
    sort -t',' -k3 citas.txt | while IFS=',' read -r hora_inicio hora_fin paciente; do
        echo -e "Paciente: ${verde}$paciente ${cierreVerde}- Hora inicio: $hora_inicio - Hora fin: $hora_fin"
    done
}

# Función para listar citas ordenadas por hora de inicio
listar_por_hora() {
    cabecera "Ordenado por hora de inicio"
    sort -t',' -k1 citas.txt | while IFS=',' read -r hora_inicio hora_fin paciente; do
        echo -e "Paciente: $paciente - Hora inicio: ${verde}$hora_inicio ${cierreVerde}- Hora fin: $hora_fin"
    done
}

# Menejo de opciones disponibles
case "$1" in
    -h|--help)
        show_help
        ;;
    -a|--add)
        shift
        add_cita "$1" "$2" "$3"
        ;;
    -d|--delete)
        eliminar_cita 
        ;;
    -s|--search)
        shift
        buscar_por_nombre "$1"
        ;;
    -i|--init)
        shift
        buscar_por_hora_inicio "$1"
        ;;
    -e|--end)
    	shift
    	buscar_por_hora_finalizacion "$1"
    	;;
    -n|--name)
        listar_por_nombre
        ;;
    -o|--hour)
        listar_por_hora
        ;;
    *)
        echo "Opción inválida. Utiliza -h o --help para ver la ayuda."
        exit 1
        ;;
esac
