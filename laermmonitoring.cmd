@echo off
chcp 1252 
REM Windows-Codepage 1252 für Umlaute in Konsole

REM psql Ordner in Pfad aufnehmen
set path=c:\Program Files\PostgreSQL\13\bin;%path%

REM Voraussetzung:
REM im lokalen PostgreSQL-Server gibt es Benutzer 'user' mit passwort '12345' mit Berechtigung 'Create Database'
SET PGUSER=user
SET PGPASSWORD=12345
REM alternativ: SET PGUSER=postgres mit vergebenem Passwort bei Installation


REM Gibtg es Datenbank laermmonitoring?
psql -l -A | find "laermmonitoring|"
if errorlevel 1 (
   Echo Erzeuge Datenbank laermmonitoring
   psql -f create_laermmonitoring.sql postgres
)

REM Download und Auspacken in Benutzer Download Ordner
REM powershell -Command "& {(Invoke-WebRequest https://test-laermmonitoring.mbbmrail.de/files/train.zip).Content | Expand-Archive -DestinationPath $env:USERPROFILE\Downloads -Force}"

REM Nur Auspacken
REM powershell -Command "& {Expand-Archive -LiteralPath $env:USERPROFILE\Downloads\train.zip     -DestinationPath $env:USERPROFILE\Downloads -Force}"
REM powershell -Command "& {Expand-Archive -LiteralPath $env:USERPROFILE\Downloads\train_all.zip -DestinationPath $env:USERPROFILE\Downloads -Force}"

REM Alles löschen
echo on
psql -c "DELETE FROM train" laermmonitoring user


@REM Importiere Daten von train.csv
type %USERPROFILE%\Downloads\train.csv | psql -c "copy train (location_id,track, entry_time, directionok, category, duration_ds, len_dm, speed_km_h, lafmax10_cb, laeq10_cb, info) from stdin WITH CSV HEADER" laermmonitoring

@REM Importiere Daten von train_all.csv, Spaltennamen müssen nicht angegeben werden, da in csv alle enthalten sind.
@REM type %USERPROFILE%\Downloads\train_all.csv | psql -c "copy train from stdin WITH CSV HEADER" laermmonitoring

pause
