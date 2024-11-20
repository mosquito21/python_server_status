import linux_metrics
from linux_metrics import cpu_stat, mem_stat, net_stat, disk_stat
import os
import json
import time, datetime


def isActive(daemon):
    command = "systemctl is-active " + daemon + " > tmp"
    os.system(command)
    with open('tmp') as tmp:
        tmp = tmp.read()
        if "inactive" in tmp:
            os.remove('tmp')
            return 0
    return 1

def since_time(daemon):
    if isActive(daemon) == 1:
        command = "systemctl show --property=ActiveEnterTimestamp " + daemon +" | cut -d '=' -f 2 "+"| cut -d ' ' -f 2,3""> tmp"
        os.system(command)
        with open('tmp') as tmp:
            tmp = tmp.read()           
            tmp = tmp.rstrip()           
            return tmp
    else:
        command = "systemctl show --property=InactiveEnterTimestamp " + daemon +" | cut -d '=' -f 2 "+"| cut -d ' ' -f 2,3"" > tmp"
        os.system(command)
        with open('tmp') as tmp:
            tmp = tmp.read()
            tmp = tmp.rstrip() 
            return tmp
        


since = since_time("apache2")

convert_to_time = datetime.datetime.strptime(since, "%Y-%m-%d %H:%M:%S")

time_to_now = datetime.datetime.now() - convert_to_time

print (since)
print(convert_to_time)
print(time_to_now)



