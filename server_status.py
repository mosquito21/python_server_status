import flask
from flask import abort
import json
import requests
import os
from functions import Functions
from functools import wraps
import dotenv

# Load environment variables

dotenv.load_dotenv()
API_KEY = os.getenv("API_KEY")

app = flask.Flask(__name__)

def requestAPIKey(view_function):
    @wraps(view_function)
    def decorated_function(*args, **kwargs):        
        api_key_received = flask.request.headers.get('X-Api-Key')
                       
        if (api_key_received and api_key_received == API_KEY):
            return view_function(*args, **kwargs)
        else:                       
            abort(
                401,
                description="API_KEY invalida o ausente"+
                str(flask.request.headers),
                )

    return decorated_function

functions = Functions()

@app.route('/server_status', methods=['GET'])
@requestAPIKey

def server_status():
    disk_total,disk_used,disk_free =functions.disk_usage()    
    cpu_usage = functions.cpu_usage()
    memory_total,memory_used = functions.ram_usage()
    try:
        mysql_status,mysql_since_time,apache_status,apache_since_time = functions.services_status()
    except:
        mysql_status,mysql_since_time,apache_status,apache_since_time = "Service not present","Service not present","Service not present","Service not present"
    
    load_avg = (functions.load_avg()[0])
    
    memory_percent = round ((memory_used/memory_total)*100,2)
    
   
   
    json_data = {
        'cpu':{
        'cpu_utilization': cpu_usage,
        'load_avg': load_avg
            },
        'disk':{
        'disk_total': disk_total,
        'disk_usage': disk_used,
        'disk_free': disk_free
            },
        'memory':{
        'memory_total':memory_total,
        'memory_used': memory_used,
        'memory_percent': memory_percent
        },
        'services':{
            'mysql':{
            'mysql_status': mysql_status,
            'since': mysql_since_time,
            },
            'apache':{
            'apache_status': apache_status,
            'since': apache_since_time
            }
        }
    }

    return json_data

