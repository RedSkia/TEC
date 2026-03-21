@echo off
mkdir dockerpublish 2>nul

echo [+] Bygger...
docker-compose build

echo [+] Gemmer image til tar...
docker save -o dockerpublish\blazorapp_image.tar blazorapp

echo [+] Kopierer setup-fil...
copy docker-compose.yml dockerpublish\

echo.
echo KLAR! Flyt mappen 'dockerpublish' til den nye PC.
echo Koer 'docker load -i blazorapp_image.tar' og derefter 'docker-compose up -d'
pause