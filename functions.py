import linux_metrics
from linux_metrics import cpu_stat, mem_stat, net_stat, disk_stat
import os
import json
import datetime, time

    


def isActive(daemon):
    command = "systemctl is-active " + daemon + " > tmp"
    os.system(command)
    with open('tmp') as tmp:
        tmp = tmp.read()
        print("status: ",tmp)
        print("len: ",len(tmp))
        if "active" in tmp and len(tmp) == 7:
            # os.remove('tmp')
            return 1
    return 0

def since_time(daemon):
    if isActive(daemon) == 1:
        command = "systemctl show --property=ActiveEnterTimestamp " + daemon +" | cut -d '=' -f 2 "+"| cut -d ' ' -f 2,3""> tmp"
        os.system(command)
        with open('tmp') as tmp:
            tmp = tmp.read()
            #quitamos el salto de linea
            try:
                tmp = datetime.datetime.strptime(tmp, "%Y-%m-%d %H:%M:%S")
                tmp = tmp.rstrip()
                tmp = datetime.datetime.now() - tmp
                tmp = str(tmp).split('.')[0]         
                return tmp
            except:
                return "No data"

    else:
        command = "systemctl show --property=InactiveEnterTimestamp " + daemon +" | cut -d '=' -f 2 "+"| cut -d ' ' -f 2,3"" > tmp"
        os.system(command)
        #verifico si el archivo contiene algo
        if os.stat("tmp").st_size <= 2:
            return "No data"
        else:        
            with open('tmp') as tmp:
                tmp = tmp.read()
                #quitamos el salto de linea
                try:
                    tmp = datetime.datetime.strptime(tmp, "%Y-%m-%d %H:%M:%S")
                    tmp = tmp.rstrip()
                    tmp = datetime.datetime.now() - tmp 
                    tmp = str(tmp).split('.')[0] 
                    return tmp
                except:
                    return "No data"

class Functions:

    def cpu_usage(self):
        metrics = cpu_stat.cpu_percents(5)

        return 100 - metrics['idle']


    # print('cpu utilization: %.2f%%' % (100 - metrics['idle']))

    def disk_usage(self):
        disk = disk_stat.disk_usage('/')

        disk_total = disk[1]/1024/1024
        disk_used = disk[2]/1024/1024
        disk_free = disk[3]/1024/1024

        return disk_total, disk_used,disk_free



    def ram_usage(self):

        used, total, _, _, _, _ = mem_stat.mem_stats()

        memory_used=used/1024/1024
        memory_total=total/1024/1024

        return memory_total, memory_used 



    def services_status(self):
      
        mysql_status= isActive('mysql')
        mysql_since_time = since_time('mysql')

        if mysql_status == 0:
            mysql_status= 'inactive'
        else:
            mysql_status= 'active'

        apache_status=isActive('apache2')
        apache_since_time = since_time('apache2')
        if apache_status == 0:
            apache_status= 'inactive'
        else:
            apache_status= 'active'

        return mysql_status,mysql_since_time, apache_status,apache_since_time
    
    def load_avg(self):
        load_avg = os.getloadavg()
        return load_avg


 