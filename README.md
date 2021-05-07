# eloverblik_to_influxdb
Bash script for querying power consumption from eloverblik.dk and inserting it in influxdb. 

Set up influxdb database as the following: 
![image](https://user-images.githubusercontent.com/64003159/117498132-ab03f900-af79-11eb-8c8a-a58531d1fded.png)


i run the script every third hour with crontab: 
0 /3 * * * /home/pi/powerLogger.sh | /usr/bin/logger -t RetrievePowerLogs
