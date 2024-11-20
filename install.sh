#!/bin/bash

# Variables dinámicas
APP_DIR=$(pwd) 
SERVICE_NAME="python_server_status.service"

# Función para verificar comandos
function check_command {
    if ! command -v $1 &> /dev/null; then
        echo "Error: $1 no está instalado. Por favor, instálalo e intenta de nuevo."
        exit 1
    fi
}

# Verificar Python 3.7+
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
if [[ $(echo "$PYTHON_VERSION >= 3.7" | bc -l) -eq 0 ]]; then
    echo "Advertencia: Python 3.7 o superior es recomendado. Encontrado: $PYTHON_VERSION"
else
    echo "Python 3.7+ encontrado: $PYTHON_VERSION"
fi

# Verificar pip o pip3
if command -v pip3 &> /dev/null; then
    PIP="pip3"
    echo "Usando pip3."
elif command -v pip &> /dev/null; then
    PIP="pip"
    echo "Usando pip."
else
    echo "Error: pip o pip3 no están instalados. Instalando pip3..."
    sudo apt-get update
    sudo apt-get install -y python3-pip
    PIP="pip3"
fi

# Verificar gunicorn
if ! command -v gunicorn &> /dev/null; then
    echo "Instalando gunicorn..."
    $PIP install gunicorn
    if ! command -v gunicorn &> /dev/null; then
        echo "Error: gunicorn no está en el PATH después de la instalación. Verifica tu entorno."
        exit 1
    fi
else
    echo "gunicorn ya está instalado."
fi

# Instalar dependencias del proyecto
echo "Instalando dependencias..."
$PIP install --upgrade pip
if [ -f "$APP_DIR/requirements.txt" ]; then
    $PIP install -r "$APP_DIR/requirements.txt"
else
    echo "Advertencia: Archivo requirements.txt no encontrado. Asegúrate de que las dependencias estén instaladas manualmente."
fi

# Crear archivo systemd para el servicio
echo "Creando archivo systemd para el servicio..."
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
sudo bash -c "cat > $SERVICE_PATH" <<EOL
[Unit]
Description=Flask API Service
After=network.target

[Service]
User=$(whoami)
Group=$(whoami)
WorkingDirectory=$APP_DIR
ExecStart=$(command -v gunicorn) -w 4 -b 0.0.0.0:5172 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Recargar systemd y habilitar el servicio
echo "Recargando systemd y habilitando el servicio..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Verificar el estado del servicio
echo "Estado del servicio:"
sudo systemctl status $SERVICE_NAME

echo "Instalación completada. API corriendo en el puerto 5172."