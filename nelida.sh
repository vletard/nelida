#!/bin/bash

HELP="
Usage: $0 [OPTIONS]... 

OPTIONS
  -h, --help      Prints this help message
  -l, --lang=code Selects between the available languages:
                  fr
  
      --unsafe    Executes the commands after a confirmation
"
#       --ext-term  Executes the commands in an external window
#                   Implies --unsafe, requires gnome-terminal
#                   (allows to launch interactive commands such as ssh)
# "
unsupported_lg="Language not supported."

if [ "${LANG:0:2}" = "fr" ]
then
  HELP="
Utilisation: $0 [OPTIONS]... 

OPTIONS
  -h, --help      Affiche ce message d'aide
  -l, --lang=code Sélectionne parmi les langue disponibles :
                  fr
  
      --unsafe    Exécute les commandes après une confirmation
"
#       --ext-term  Exécute les commandes dans une fenêtre externe
#                   Implique --unsafe, requiert gnome-terminal
#                   (permet les commandes interactives telles que ssh)
# "
  unsupported_lg="Langue non prise en charge."
fi

safe=true
ext_term=false
lang=fr

######################################################
# Parsing the command line
TEMP=`getopt -o hl: --long help,unsafe,lang: -n "$0" -- "$@"`

if [ $? != 0 ] ; then echo "Abandon" >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

while true ; do
	case "$1" in
    -l|--lang)
      if [ "$2" != "fr" ]
      then
        echo $unsupported_lg
      fi
      # TODO
      shift 2 ;;
    --unsafe)
      safe=false
      shift ;;
    --ext-term)
      safe=false
      ext_term=true
      shift ;;
		-h|--help)
      echo "$HELP"
      exit 0 ;;
		--) shift ; break ;;
		*) echo "Internal error!" ; exit 1 ;;
	esac
done

######################################################


rlwrap=$(which rlwrap)

if [ "$rlwrap" = "" ]
then
echo "
Note : Il est recommandé d'installer le paquet rlwrap pour une meilleure
       expérience utilisateur. Cela permet la complétion des noms de fichiers
       et le rappel de requêtes ou de commandes déjà utilisées.
"
fi

if $ext_term
then
  prompt='echo -n $(date "+[%m-%d %H:%M:%S]") $(whoami)@$(hostname):$(pwd)\>" "'
  session=$(mktemp -u)
  mkfifo $session
  gnome-terminal -e "cat $session | ssh localhost"
  exec 3> $session
  echo "Ce terminal externe est en lecture seule." >&3
  echo "Placez-le à côté de votre console Nelida." >&3
  eval $prompt >&3
fi

running=true
request_prompt="> "
command_prompt="$ "
ilar_options="-d 1 --time 2" # --source-segmentation characters"
log_path=~/.nelida/log/
db_path=~/.nelida/db/
log_err=$(date "+%y%m%d_%H%M%S_log_err.txt.gz")
log=$(date "+%y%m%d_%H%M%S_log.txt.gz")
pushd $(dirname $0) > /dev/null
path=$(pwd -P)
popd > /dev/null

mkdir -p $log_path $db_path
touch $db_path/incremental.{in,out}.txt

printf "detail db %s %s\n\n" "$(wc < $db_path/incremental.in.txt)" "$(wc < $db_path/incremental.out.txt)" | gzip >> $log_path/$log

echo "
Note : Les commandes que vous utilisez dans ce système sont enregistrées dans
       les fichiers de logs qui vous seront demandés à l'issue de l'expérience.
       N'utilisez pas de commandes sensibles (qui requièrent des mots de passe
       en clair ou autre donnée personnelle ou sensible).
"
echo "Je suis Nelida, que puis-je pour vous ?"

while $running
do
  echo
  if [ "$rlwrap" != "" ]
  then
    request=$(rlwrap -C "nelida_request" -S "$request_prompt" -co cat)
  else
    read -p "$request_prompt" request
  fi
  if [ "$request" != "" ]
  then
    tmp=$(mktemp)
    tmp_err=$(mktemp)
    pushd $path/analogy/ > /dev/null
    echo "$request" | ./ilar.sh -p $db_path/incremental $ilar_options 2> $tmp_err > $tmp
    gzip < $tmp_err >> $log_path/$log_err
    rm -f $tmp_err
    gzip < $tmp >> $log_path/$log
    if (( $? != 0 ))
    then
      printf "L'appel à ILAR a échoué, consultez le fichier de log : %s\n" "$log_path/$log" >&2
      rm -f $tmp
      exit 1
    fi
    popd > /dev/null
    dev=$(grep "^detail deviation" < $tmp | wc -l)
    ans=$(grep "^final" < $tmp | cut -b 7-)
    rm -f $tmp
    mem=false
    learn=false
    if [ "$ans" = "" ]
    then
      echo "Je ne sais pas comment faire."
      learn=true
    else
      if (( $dev > 0 ))
      then
        printf "Je ne suis pas sûr.. Je pense à quelque chose comme ça :\n"
      fi
      printf "\n$ %s\n\n" "$ans"
      read -n1 -p "Est-ce correct ? (o)ui/(n)on/(A)nnuler " validate
      echo
      if [ "$validate" = "O" ] || [ "$validate" = "o" ]
      then
        mem=true
      else
        if [ "$validate" = "N" ] || [ "$validate" = "n" ]
        then
          printf "status invalid\n\n" | gzip >> $log_path/$log
          learn=true
        fi
      fi
    fi
    if $learn
    then
      read -n1 -p "Pouvez-vous/souhaitez-vous m'apprendre ? (O)ui/(n)on " show
      echo
      if [ "$show" = "O" ] || [ "$show" = "o" ] || [ "$show" = "" ]
      then
        echo "Entrez la commande correcte : "
        if [ "$rlwrap" != "" ]
        then
          ans=$(rlwrap -C "nelida_command" -S "$command_prompt" -co cat)
        else
          read -p "$command_prompt" ans
        fi
        if [ "$ans" != "" ]
        then
          mem=true
        fi
      fi
    fi

    if $mem
    then
      confirm=true
      if ! $safe
      then
        if ! $ext_term
        then
          echo "Le contexte actuel est $(whoami)@$(hostname):$(pwd)"
        fi
        read -n1 -p "Dois-je exécuter la commande dans ce contexte ? (o)ui/(N)on " exe
        echo
        if [ "$exe" = "o" ] || [ "$exe" = "O" ]
        then
          if $ext_term
          then
            echo $ans >&3
            eval $ans >&3
            if $ext_term
            then
              eval $prompt >&3
            fi
          else
            echo
            eval $ans
            echo
            printf "Commande exécutée, code de retour : %d\n" "$?"
          fi
          read -n1 -p "Cela a-t-il fonctionné comme prévu ? (o)ui/(n)on/(A)nnuler " ok
          echo
          if [ "$ok" != "o" ] && [ "$ok" != "O" ]
          then
            confirm=false
          fi
        else
          confirm=false
        fi
      fi
      if $confirm
      then
        if ! $learn
        then
          printf "status valid\n\n" | gzip >> $log_path/$log
        fi
        tmp_file=$(mktemp)
        printf '%s\t%s\n' "$request" "$ans" > $tmp_file
        if (( $(wc -l < $db_path/incremental.in.txt) < $(paste $db_path/incremental.in.txt $db_path/incremental.out.txt | cat - $tmp_file | LANG= sort | uniq | wc -l) ))
        then
          echo "$request" >> $db_path/incremental.in.txt
          echo "$ans"     >> $db_path/incremental.out.txt
          printf "Bien. Je mémorise l'association. (%d au total)\n" $(wc -l < $db_path/incremental.in.txt)
        fi
        rm -f $tmp_file
      fi
    fi

    echo "Entrez votre requête. Une ligne vide ou <ctrl>-d pour quitter."
  else
    running=false
  fi
done

if $ext_term
then
  exec 3>&-
  rm -f $session
fi

echo "Au revoir."
