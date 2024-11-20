#!/bin/bash

# Variables dinámicas
APP_DIR=$(pwd)  # Obtiene la ruta actual del script
SERVICE_NAME="python_server_status.service"

# Función para verificar comandos
function check_command {
    if ! command -v $1 &> /dev/null; then
        echo "Error: $1 no está instalado. Por favor, instálalo e intenta de nuevo."
        exit 1
    fi
}

#verifico que exista pip
PIP=check_command "pip"

if [ -z "$PIP" ]; then
    echo "Instalando pip..."
    sudo apt-get install python3-pip
fi

#instalo gunicorn
GUNICORN=check_command "gunicorn"

if [ -z "$GUNICORN" ]; then
    echo "Instalando gunicorn..."
    pip install gunicorn
fi


# Instalar dependencias
echo "Instalando dependencias..."
pip install --upgrade pip
pip install -r $APP_DIR/requirements.txt
pip install gunicorn

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
ExecStart=/bin/gunicorn -w 4 -b 0.0.0.0:5000 app:app
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

echo "Instalación completada. API corriendo en el puerto 5000."