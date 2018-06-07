#!/bin/bash
Name1=$(storageAccountName)
Name2=$(storageAccountName)
Name3=$(Resourcegroup)
touch /tmp/extresults.txt
echo "$Name1 $Name2 $Name3 >> /tmp/extresults.txt" 
