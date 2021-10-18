# preingest-utilities
Utilities voor de preingest tool

Bevat webhooks voor o.a. 
- alle metadata bestanden in een collectie uitlezen en opslaan naar Excel 
- het splitten van collecties
- een map uploaden naar AWS S3 bucket

# Container compileren
In de map waar Dockerfile zich bevindt, voer uit in commandline: docker build -t noordhollandsarchief/preingest-utilities .

# Container uitvoeren
Container uitvoeren, voer uit in commandline: docker run --rm -d -p 9000:9000 -v {AWS_CONFIGURATIE_MAP}:/root/.aws -v {PREINGEST_DATA_MAP}:/data noordhollandsarchief/preingest-utilities

{AWS_CONFIGURATIE_MAP} : Map waarin twee bestanden staan met configuratie naar AWS S3 Bucket.
{PREINGEST_DATA_MAP} : Map waar collecties staan voor preingest stappen.

Uiteraard port nummer kan gewijzigd worden naar eigen behoefte. Voor de voorbeelden houden we op port nummer 9000 aan.

# Beschikbare hooks
- http://localhost:9000/hooks/listbucket
- http://localhost:9000/hooks/clearbucket
- http://localhost:9000/hooks/upload2bucket?guid={0}
- http://localhost:9000/hooks/compress-collection?archiveName={0}&collectionName={1}&folder={2}
- http://localhost:9000/hooks/uncompress-collection?archiveName={0}
- http://localhost:9000/hooks/flat-transform?file={0}
- http://localhost:9000/hooks/flat-metadata?archiveName={0}
- http://localhost:9000/hooks/split-collection?archiveName={0}&splitSize={1}

# Docker-compose
Wordt vervolgd. Tool is nog in ontwikkeling.
