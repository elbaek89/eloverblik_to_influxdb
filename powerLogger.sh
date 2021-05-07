#!/bin/bash
# uses jq (sudo apt-get install jq)
# script pulls from two meters (since i have solar panels, i can get production from separate meter). If that isn't needed, just remove the second meterpoint id and modify where needed. 
# For the first time you run it, you can modify the dayNum loop from {2..0} to a larger number, e.g. 365..0 to pull previous data. Just remember to 
# reset the number afterwards if you plan on running the script regularly. 
# The last thing you need is to create the influxdb table you want to push to - i had no trouble there. 

# 1. Retrieve token
RefreshToken=eyJhbGciOiJIUzI1...
MeterPointID="571XXXXXXXXXXXXXXX"
MeterPointID_deliveredToGrid="571XXXXXXXXXXXXXXX"

AccessToken=$(curl -s -X GET "https://api.eloverblik.dk/CustomerApi/api/token" -H  "accept: application/json" -H  "Authorization: Bearer $RefreshToken" | jq -r '.result')

echo "Retrieving power consumption and production data from eloverblik.dk..."

for dayNum in {2..0}
do

   Date1=$(date -d @$(( $(date +"%s") - 86400*($dayNum+1))) +"%Y-%m-%d")
   Date2=$(date -d @$(( $(date +"%s") - 86400*$dayNum)) +"%Y-%m-%d")

   # 2. Retrieve data
   ResponseJSON_consumption=$(curl -s -X POST "https://api.eloverblik.dk/CustomerApi/api/meterdata/gettimeseries/$Date1/$Date2/Hour" -H  "accept: application/json" -H  "Authorization: Bearer $AccessToken" -H  $
   ResponseJSON_production=$(curl -s -X POST "https://api.eloverblik.dk/CustomerApi/api/meterdata/gettimeseries/$Date1/$Date2/Hour" -H  "accept: application/json" -H  "Authorization: Bearer $AccessToken" -H  "$

   values_consumption=( $(jq -r '.result[].MyEnergyData_MarketDocument.TimeSeries[].Period[].Point[]."out_Quantity.quantity"' <<< "$ResponseJSON_consumption") )
   values_production=( $(jq -r '.result[].MyEnergyData_MarketDocument.TimeSeries[].Period[].Point[]."out_Quantity.quantity"' <<< "$ResponseJSON_production") )


   # I let the range be 0..23 and add one hour in the convertion to unix, since the time YYYY-MM-DD 24:00.00 produces an error.
   for hourNum in {0..23}
   do
      # Generate UNIX timestamp
      timestamp_posix[hourNum]=$(( $(date "+%s" -d "$Date1 $hourNum:00:00") + 60*60))

      curl -i --silent -XPOST 'http://localhost:8086/write?db=powerConsumption&precision=s' --data-binary "consumedFromGrid,meter=MeterName value=${values_consumption[$hourNum]} ${timestamp_posix[$hourNum]}"
      curl -i --silent -XPOST 'http://localhost:8086/write?db=powerConsumption&precision=s' --data-binary "deliveredToGrid,meter=MeterName value=${values_production[$hourNum]} ${timestamp_posix[$hourNum]}"

   done

done
echo "Done..."
