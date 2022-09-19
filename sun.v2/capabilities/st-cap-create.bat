set capability=%1
set inputFile=%capability%.cap.yaml
set outputFile= %capability%-response-create.cap.yaml
smartthings capabilities:create -y -i %inputFile% -o %outputFile%
