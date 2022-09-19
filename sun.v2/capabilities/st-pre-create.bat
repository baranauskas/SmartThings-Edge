set capability=%1
set presentation=%2
set capabilityID=returnamber36996.%capability%
set inputFile=%capability%.pre.yaml
set outputFile=%capability%-response-create.pre.yaml
smartthings capabilities:presentation:create %capabilityID% 1 -y -i %inputFile% -o %outputFile%
