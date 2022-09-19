set capability=%1
set capabilityID=returnamber36996.%capability%
set inputFile=%capability%.cap.yaml
set outputFile= %capability%-response-create.cap.yaml
smartthings capabilities:update %capabilityID% 1 -y -i %inputFile% -o %outputFile%
