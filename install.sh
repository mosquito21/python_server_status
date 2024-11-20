#!/bin/bash

# Variables dinámicas
APP_DIR=$(pwd)  # Obtiene la ruta actual del script
SERVICE_NAME="python_server_status.service"
VENV_DIR="$APP_DIR/venv"

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
    echo "Error: Se requiere Python 3.7 o superior. Encontrado: $PYTHON_VERSION"
    exit 1
else
    echo "Python 3.7+ encontrado: $PYTHON_VERSION"
fi

# Verificar pip
check_command "pip3"

# Verificar virtualenv
if ! python3 -m venv --help &> /dev/null; then
    echo "Error: virtualenv no está disponible. Por favor, instala virtualenv:"
    echo "  pip3 install virtualenv"
    exit 1
else
    echo "virtualenv está disponible."
fi

# Crear el entorno virtual si no existe
if [ ! -d "$VENV_DIR" ]; then
    echo "Creando entorno virtual en $VENV_DIR..."
    python3 -m venv $VENV_DIR
else
    echo "Entorno virtual ya existe en $VENV_DIR."
fi

# Activar el entorno virtual
echo "Activando entorno virtual..."
source $VENV_DIR/bin/activate

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
ExecStart=$VENV_DIR/bin/gunicorn -w 4 -b 0.0.0.0:5000 app:app
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