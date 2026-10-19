#!/bin/bash
TODAY=$(date +%F)   #format YYYY-MM-JJ
LOG="logs/run_$TODAY.log"
ID=0  

mkdir -p input output archive errors trash logs 
[ -s "output/report_$TODAY.csv" ] || echo "id,date,city,reason,count" > "output/report_$TODAY.csv"   

log() {                              
  echo "$1" | tee -a "$LOG"   #$1 est le premier argument donné à la fonction
}

#Nettoyage
for f in input/*.tmp; do
  [ -e "$f" ] || continue          
  mv "$f" trash/
  log "[$(date +%H:%M)] INFO: moved $(basename "$f") to trash/"
done

#Fct
process_file() {
  local file="$1"
  local name city reason count
  name=$(basename "$file")
  log "[$(date +%H:%M)] INFO: job started"
  log "[$(date +%H:%M)] INFO: reading input/$name"

  if head -n 1 "$file" | grep -q "reason"; then

    case "$name" in
      returns_agadir.csv) city="Agadir" ;;
      returns_casa.csv)   city="Casablanca" ;;
      returns_tanger.csv) city="Tanger" ;;
      *)
        mv "$file" errors/
        log "[$(date +%H:%M)] ERROR: unknown file $name"
        log "[$(date +%H:%M)] INFO: job finished"
        return
        ;;
    esac

    for reason in defective wrong_item changed_mind; do
      count=$(grep -c ",${reason}," "$file")
      ID=$((ID + 1))
      echo "$ID,$TODAY,$city,$reason,$count" >> "output/report_$TODAY.csv"
      log "[$(date +%H:%M)] INFO: $city $reason = $count"
    done

    mv "$file" "archive/$(basename "$file" .csv)_$TODAY.csv"
    log "[$(date +%H:%M)] INFO: archived as $(basename "$file" .csv)_$TODAY.csv"
  else
    mv "$file" errors/
    log "[$(date +%H:%M)] ERROR: missing column 'reason' in $name"
  fi

  log "[$(date +%H:%M)] INFO: job finished"
}

#Boucle lançant le traitement
for f in input/*.csv; do
  [ -e "$f" ] || continue         
  process_file "$f"
done