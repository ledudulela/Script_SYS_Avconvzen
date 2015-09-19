#!/bin/bash
scriptVersion="1.3"
#---------------------------------------------------------------------------------------------------------------------
# auteur: ledudulela 
# màj: 2015-06-25 17:00
# objet: Conversion de vidéo avec liste de choix possibles (codecs+dimensions) 
# Le chemin du fichier cible final sera de la forme: 
#   /repertoireFichierSource/nomFichierSource_ancienneExtension_LxH.nouvelleExtension
# Exemple:
#   /home/user/Vidéos/ma.Video.MPG  -->  /home/user/Vidéos/ma.Video_MPG_640x360.avi
#---------------------------------------------------------------------------------------------------------------------
# utilisation:
# avconvzen chemin_du_fichier 
# avconvzen -h : affiche l'aide sur les différents paramètres possibles du script
#---------------------------------------------------------------------------------------------------------------------
# attention, le paramètre --text de zenity est en html, 
# il faut remplacer les caractères spéciaux comme par exemple & par &amp;
# cela peut être bloquant en particulier avec conjointement --question --text
# ce problème n'existe pas avec l'option --title
#
# Exemples de remplacement de chaine avec sed:
# -------------------------------------------
# strReplace=$(echo "$var" | sed 's/search/replace/g')
# strZenText=$(echo "$selectedFileName" | sed 's/&/&amp;/g')
# zenity --info --title="$selectedFileName" --text="$strZenText"
#
# sed 's/\(.*\)\.mpeg/\1.mpg/' fichier
# remplace les noms de fichier se terminant par .mpeg par des noms de fichier se terminant par .mpg
# ici, \1 est remplacé par le premier groupe, répondant à l'expression entre \( et \)
#---------------------------------------------------------------------------------------------------------------------
# Nbr de paramètres sh: $#
# Chemin du script sh : $0
# Premier paramètre   : $1
# echo $? affiche le code de sortie (exit) de la dernière commande (0 quand cela se passe bien)
#---------------------------------------------------------------------------------------------------------------------

# -----------------------------------------
# --- Définition des valeurs par défaut ---
# -----------------------------------------
defaultAB=128k	# qualité audio par défaut
defaultVB=4096k	# qualité vidéo par défaut

# ------------------------------------------
# --- Déclaration du tableau des options ---
# ------------------------------------------
declare -A arrOption # 0=identifiant (fait le lien entre le tableau et la radiolist), 1=libellé encodage, 2=extension fichier cible
arrOption[1,0]=1
arrOption[1,1]="xvid + ac3 - 640x480 .avi"
arrOption[1,2]="_640x480.avi"
arrOption[2,0]=2
arrOption[2,1]="xvid + ac3 - 640x360 .avi"
arrOption[2,2]="_640x360.avi"
arrOption[3,0]=3
arrOption[3,1]="xvid + ac3 - 1024x576 .avi"
arrOption[3,2]="_1024x576.avi"
arrOption[4,0]=4
arrOption[4,1]="xvid + ac3 - 1280x720 .avi"
arrOption[4,2]="_1280x720.avi"
arrOption[5,0]=5
arrOption[5,1]="h264 + aac - 640x480 .mp4"
arrOption[5,2]="_640x480.mp4"
arrOption[6,0]=6
arrOption[6,1]="h264 + aac - 640x360 .mp4"
arrOption[6,2]="_640x360.mp4"
arrOption[7,0]=7
arrOption[7,1]="h264 + aac - 1024x576 .mp4"
arrOption[7,2]="_1024x576.mp4"
arrOption[8,0]=8
arrOption[8,1]="h264 + aac - 1280x720 .mp4"
arrOption[8,2]="_1280x720.mp4"
arrOption[9,0]=9
arrOption[9,1]="h264 + aac - 1920x1080 .mp4"
arrOption[9,2]="_1920x1080.mp4"
arrOption[10,0]=10
arrOption[10,1]="Réencapsule simplement en mp4"
arrOption[10,2]=".mp4"
arrOption[11,0]=11
arrOption[11,1]="Corrige aac et encapsule en mp4"
arrOption[11,2]=".mp4"
arrOption[12,0]=12
arrOption[12,1]="Réencapsule simplement en mkv"
arrOption[12,2]=".mkv"

# ---------------------------------------------
# --- mémorise le nbr d'éléments du tableau ---
# ---------------------------------------------
valMaxOption=$((${#arrOption[*]} / 3))
# ---------------------------------------------

# ---------------------------------
# ---  Définition de fonctions  ---
# ---------------------------------
isEqual() # renvoie Vrai si le 1er argument est égal au 2ème argument
{ 
    if [ ${1} -eq ${2} ] 
    then 
           echo TRUE
	else
           echo FALSE
    fi 
}

# -----------------------------------------------
# --- Traitement du nbr d'arguments du script ---
# -----------------------------------------------
if [ $# -lt 1 ] # si le nbr de paramètres en entrée est égal à 0 (il faut au moins un nom de fichier) alors le script est interrompu.
then
	zenity --error --text="Nombre de paramètres incorrect.\n\nTapez  avconvzen -h  pour plus de détails." 2>/dev/null
	exit 10 # définit au passage un code de sortie pour cette interruption
fi

# -----------------------------------------------
# --- Traitement des arguments de la commande ---
# -----------------------------------------------
while getopts o:x:thlv arg
do
 case $arg in
	o) # l'argument -o (de type entier) permet de redéfinir l'option par défaut
		if let $OPTARG 2>/dev/null && (( "$OPTARG" <= "$valMaxOption" )); then # l'argument doit être un entier existant
			defaultOption=$OPTARG # variable non précédée de $
		fi
	;;
	x) # l'argument -x (de type entier) permet de redéfinir l'encodage à exécuter automatiquement
		if let $OPTARG 2>/dev/null && (( "$OPTARG" <= "$valMaxOption" )); then # l'argument doit être un entier existant
			autoexecOptionId=$OPTARG # variable non précédée de $
		fi
	;;
	t)
		outputTmpDir=TRUE
	;;
	l)
		withLog=TRUE
	;;
	v)
		zenity --info --title="Version" --text="avconvzen - version $scriptVersion" 2>/dev/null
		exit 0
	;;
	h)
		zenity --info --title="Aide" --text="\
<u>Utilisation:</u> \n\n \
<b>avconvzen fichier</b> \n\n \
avconvzen <b>-o</b>2 fichier (la 2ème option de la liste est sélectionnée par défaut) \n\n \
avconvzen <b>-x</b>3 fichier (l'encodage est exécuté automatiquement avec la 3ème option \n \
et, si le fichier cible existe déjà, le remplace sans confirmation) \n\n \
avconvzen <b>-v</b> (affiche le numéro de version du script) \n\n \
avconvzen <b>-l</b> fichier (active la journalisation dans le fichier .log) \n\n \
avconvzen <b>-t</b> fichier (le fichier cible sera créé dans le répertoire /tmp) \n\n \
\n \
<u>Remarque:</u> \n\n \
Par défaut, le fichier cible est créé dans le répertoire du fichier source. \n\n \
Le chemin du fichier final sera de la forme: \n \
/repertoireFichierSource/nomFichierSource_ancienneExtension_LxH.nouvelleExtension \n\n \
\n \
<u>Exemple:</u> \n\n \
Chemin du fichier source à convertir: \n /home/user/Vidéos/ma.Video.MOV \n\n \
Chemin du fichier cible après conversion: \n /home/user/Vidéos/ma.Video_MOV_640x360.avi" \
2>/dev/null
		exit 0
	;;
 esac
done

if [ -z "$defaultOption" ] # teste si la variable est définie
then
	defaultOption=1 # l'option 1 de la radiolist sera sélectionnée par défaut
fi

# -------------------------------------
# --- Traitement du type de fichier ---
# -------------------------------------
last_arg="${!#}" # le fichier doit être le dernier argument de la ligne de commande
selectedFileType=$(file -b --mime-type "$last_arg" | awk -F "/" '{print $1}')	# type du fichier à convertir (video/muxer)
#if [ "$selectedFileType" != "video" ] # si le fichier n'est pas de type vidéo alors le script est interrompu: désactivé car pb avec certains fichiers.ts
#then
#	zenity --error --text=" Le fichier de type -$selectedFileType- ne semble pas \n être une vidéo valide. " 2>/dev/null
#	exit 20 # définit au passage un code de sortie pour cette interruption
#fi

# ------------------------------------
# --- Traitement du nom de fichier ---
# ------------------------------------
selectedFilePath="$last_arg"						# chemin complet du fichier à convertir
selectedDirectory=$(dirname "$selectedFilePath") 			# répertoire du fichier à convertir
cptElt=$(basename "$selectedFilePath" | awk -F "." '{print NF}')	# nbr d'éléments (NF) du split(nom_fichier,".")
if [ $cptElt == 1 ] 
then
	# cas où le nom de fichier ne contient pas de point (.) et donc pas d'extension
	selectedFileName=$(basename "$selectedFilePath")
	outputFilePath=${selectedDirectory}\/${selectedFileName}
else
	# cas où le nom de fichier contient un ou plusieurs points (.) et donc l'extension est normalement le dernier élément
	selectedFileExt=$(basename "$selectedFilePath" | awk -F "." '{print $NF}')		# extension du nom de fichier (dernier élément=$NF)
	# selectedFileName=$(basename "$selectedFilePath" | awk -F "." '{print $1}') 		# nom du fichier sans l'extension (bug si plusieurs points)
	selectedFileName=$(basename "$selectedFilePath" | sed "s/\(.*\)\.$selectedFileExt/\1/") # nom du fichier sans l'extension
	outputFilePath=${selectedFileName}\_${selectedFileExt} 		# modèle de chemin du fichier à créer (ex: /dir/myVideo_mov)
	if [ -z "$outputTmpDir" ]; then # si la variable n'est pas définie...
		outputFilePath=${selectedDirectory}\/${outputFilePath} # fichier cible dans le répertoire du fichier source
	else
		outputFilePath='/tmp/'${outputFilePath} # fichier cible dans le répertoire temporaire
	fi
fi

# -----------------------------------------------
# --- Traitement de la liste de boutons radio ---
# -----------------------------------------------
if [ ! -z "$autoexecOptionId" ] # affiche la liste de choix si la variable n'est pas définie ( l'argument -x n'a pas été spécifié en paramètre de script)
then
	choixEncodage=$autoexecOptionId # pour l'exécution automatique sans proposer la liste de choix
else
	# on masque la colonne ID mais la variable choixEncodage contiendra l'ID sélectionné car c'est la colonne qui suit le bouton radio
	choixEncodage=$(zenity --list \
		--title="$selectedFileName" \
		--text="<i>Type de conversion (vb:$defaultVB ab:$defaultAB)</i>" \
		--radiolist \
		--width 310 \
		--height 340 \
		--hide-header \
		--hide-column=2 \
		--column "radio" --column "id" --column "num" --column "libellé" \
		$(isEqual $defaultOption 1) "${arrOption[1,0]}" "${arrOption[1,0]}". "${arrOption[1,1]}" \
		$(isEqual $defaultOption 2) "${arrOption[2,0]}" "${arrOption[2,0]}". "${arrOption[2,1]}" \
		$(isEqual $defaultOption 3) "${arrOption[3,0]}" "${arrOption[3,0]}". "${arrOption[3,1]}" \
		$(isEqual $defaultOption 4) "${arrOption[4,0]}" "${arrOption[4,0]}". "${arrOption[4,1]}" \
		$(isEqual $defaultOption 5) "${arrOption[5,0]}" "${arrOption[5,0]}". "${arrOption[5,1]}" \
		$(isEqual $defaultOption 6) "${arrOption[6,0]}" "${arrOption[6,0]}". "${arrOption[6,1]}" \
		$(isEqual $defaultOption 7) "${arrOption[7,0]}" "${arrOption[7,0]}". "${arrOption[7,1]}" \
		$(isEqual $defaultOption 8) "${arrOption[8,0]}" "${arrOption[8,0]}". "${arrOption[8,1]}" \
		$(isEqual $defaultOption 9) "${arrOption[9,0]}" "${arrOption[9,0]}". "${arrOption[9,1]}" \
		2>/dev/null
	)

	# mémorise l'option choisie dans un fichier si celui-ci est déclaré (export) dans un script parent
	# c est pratique avec une multi-sélection de fichiers. Le choix (ou l'annulation) ne sera demandé qu'une fois.
	if [ -n "$fileLastOption" ]; then # si la variable existe...
		if [ $? == 1 ]; then # teste si le bouton [Annuler] a été cliqué
			echo '0' > "$fileLastOption"
		else
			echo $choixEncodage > "$fileLastOption"
		fi
	fi

	# ---------------------------------------------------
	# ---- Traitement du clic sur bouton [Annuler] ------
	# ---------------------------------------------------
	if [ $? == 1 ] # teste si le bouton [Annuler] a été cliqué
	then
		# Si clic bouton [Annuler] alors le script est interrompu.
		exit 30
	fi
fi


# -------------------------------------------------------------
# --- Génère la ligne de commande selon le choix d'encodage ---
# -------------------------------------------------------------
outputFilePath=${outputFilePath}${arrOption[$choixEncodage,2]} # complète le nom avec l'extension correspondante au choixEncodage
case $choixEncodage in 
	${arrOption[1,0]}) 
		cmdConv='avconv -y -i "$selectedFilePath" -f avi -vcodec libxvid -vtag XVID -vf scale=640:480 -aspect 4:3 -b:v $defaultVB -qmin 3 -qmax 5 -bufsize 4096 -mbd 2 -bf 2 -trellis 1 -flags +aic -cmp 2 -subcmp 2 -g 300 -acodec ac3 -ar 48000 -b:a $defaultAB -ac 2 "$outputFilePath"';;
	${arrOption[2,0]})
		cmdConv='avconv -y -i "$selectedFilePath" -f avi -vcodec libxvid -vtag XVID -vf scale=640:360 -aspect 16:9 -b:v $defaultVB -qmin 3 -qmax 5 -bufsize 4096 -mbd 2 -bf 2 -trellis 1 -flags +aic -cmp 2 -subcmp 2 -g 300 -acodec ac3 -ar 48000 -b:a $defaultAB -ac 2 "$outputFilePath"';;
	${arrOption[3,0]})
		cmdConv='avconv -y -i "$selectedFilePath" -f avi -vcodec libxvid -vtag XVID -vf scale=1024:576 -aspect 16:9 -b:v $defaultVB -qmin 3 -qmax 5 -bufsize 4096 -mbd 2 -bf 2 -trellis 1 -flags +aic -cmp 2 -subcmp 2 -g 300 -acodec ac3 -ar 48000 -b:a $defaultAB -ac 2 "$outputFilePath"';;
	${arrOption[4,0]})
		cmdConv='avconv -y -i "$selectedFilePath" -f avi -vcodec libxvid -vtag XVID -vf scale=1280:720 -aspect 16:9 -b:v $defaultVB -qmin 3 -qmax 5 -bufsize 4096 -mbd 2 -bf 2 -trellis 1 -flags +aic -cmp 2 -subcmp 2 -g 300 -acodec ac3 -ar 48000 -b:a $defaultAB -ac 2 "$outputFilePath"';;
	${arrOption[5,0]})
		cmdConv='avconv -y -i "$selectedFilePath" -f mp4 -vcodec libx264 -preset slow -vf scale=640:480 -b:v $defaultVB -flags +loop -cmp chroma -maxrate $defaultVB -bufsize 4M -bt 256k -refs 1 -bf 3 -coder 1 -me_method umh -me_range 16 -subq 7 -partitions +parti4x4+parti8x8+partp8x8+partb8x8 -g 250 -keyint_min 25 -level 30 -qmin 10 -qmax 51 -qcomp 0.6 -trellis 2 -sc_threshold 40 -i_qfactor 0.71 -acodec aac -strict experimental -b:a $defaultAB -ar 48000 -ac 2 "$outputFilePath"';;
	${arrOption[6,0]})
		cmdConv='avconv -y -i "$selectedFilePath" -f mp4 -vcodec libx264 -preset slow -vf scale=640:360 -b:v $defaultVB -flags +loop -cmp chroma -maxrate $defaultVB -bufsize 4M -bt 256k -refs 1 -bf 3 -coder 1 -me_method umh -me_range 16 -subq 7 -partitions +parti4x4+parti8x8+partp8x8+partb8x8 -g 250 -keyint_min 25 -level 30 -qmin 10 -qmax 51 -qcomp 0.6 -trellis 2 -sc_threshold 40 -i_qfactor 0.71 -acodec aac -strict experimental -b:a $defaultAB -ar 48000 -ac 2 "$outputFilePath"';;
	${arrOption[7,0]})
		cmdConv='avconv -y -i "$selectedFilePath" -f mp4 -vcodec libx264 -preset slow -vf scale=1024:576 -b:v $defaultVB -flags +loop -cmp chroma -maxrate $defaultVB -bufsize 4M -bt 256k -refs 1 -bf 3 -coder 1 -me_method umh -me_range 16 -subq 7 -partitions +parti4x4+parti8x8+partp8x8+partb8x8 -g 250 -keyint_min 25 -level 30 -qmin 10 -qmax 51 -qcomp 0.6 -trellis 2 -sc_threshold 40 -i_qfactor 0.71 -acodec aac -strict experimental -b:a $defaultAB -ar 48000 -ac 2 "$outputFilePath"';;
	${arrOption[8,0]})
		cmdConv='avconv -y -i "$selectedFilePath" -f mp4 -vcodec libx264 -preset slow -vf scale=1280:720 -b:v $defaultVB -flags +loop -cmp chroma -maxrate $defaultVB -bufsize 4M -bt 256k -refs 1 -bf 3 -coder 1 -me_method umh -me_range 16 -subq 7 -partitions +parti4x4+parti8x8+partp8x8+partb8x8 -g 250 -keyint_min 25 -level 30 -qmin 10 -qmax 51 -qcomp 0.6 -trellis 2 -sc_threshold 40 -i_qfactor 0.71 -acodec aac -strict experimental -b:a $defaultAB -ar 48000 -ac 2 "$outputFilePath"';;
	${arrOption[9,0]})
		cmdConv='avconv -y -i "$selectedFilePath" -f mp4 -vcodec libx264 -preset slow -vf scale=1920:1080 -b:v $defaultVB -flags +loop -cmp chroma -maxrate $defaultVB -bufsize 4M -bt 256k -refs 1 -bf 3 -coder 1 -me_method umh -me_range 16 -subq 7 -partitions +parti4x4+parti8x8+partp8x8+partb8x8 -g 250 -keyint_min 25 -level 30 -qmin 10 -qmax 51 -qcomp 0.6 -trellis 2 -sc_threshold 40 -i_qfactor 0.71 -acodec aac -strict experimental -b:a $defaultAB -ar 48000 -ac 2 "$outputFilePath"';;
	${arrOption[10,0]})
		cmdConv='avconv -y -i "$selectedFilePath" -vcodec copy -acodec copy "$outputFilePath"';;
	${arrOption[11,0]})
		cmdConv='avconv -y -i "$selectedFilePath" -vcodec copy -acodec copy -bsf:a aac_adtstoasc "$outputFilePath"';;
	${arrOption[12,0]})
		cmdConv='avconv -y -i "$selectedFilePath" -vcodec copy -acodec copy "$outputFilePath"';;
	*)
		cmdConv='exit 1';;
esac

# ---------------------------------------------------------------
# --- Traitement au cas où le fichier cible existerait déjà  ----
# ---------------------------------------------------------------
outputFileName=$(basename "$outputFilePath")
if [ -z "$autoexecOptionId" ]; then # uniquement si la variable n'est pas définie...
	if [ -f "$outputFilePath" ] # teste si le fichier cible existe déjà 
	then
		# le fichier cible existe déjà, demande alors si on veut le remplacer
		#outputFileNameZ=$(basename "$outputFilePath" | sed 's/&/&amp;/g') # remplace & par &amp; pour du texte html
		zenity --question --title="$outputFileName" --text=" Le fichier existe déjà, voulez-vous le remplacer ?" 2>/dev/null
		flag_annul=$? # 0 = bouton Oui (on remplace) ; 1 = bouton Non (on ne remplace pas)
	else
		flag_annul=0 # le fichier cible n'existe pas encore
	fi

	if [ $flag_annul != 0 ]
	then
		# Cas où le fichier cible existe déjà mais qu'on ne veut pas le remplacer alors le script est interrompu.
		exit 40
	fi
fi	
# --------------------------------------------------------------------------------------
# --- Exécute la commande avec une fenêtre popup s'affichant le temps du traitement  ---
# --------------------------------------------------------------------------------------
libEncodage='('${arrOption[$choixEncodage,0]}' : '${arrOption[$choixEncodage,1]}')' # libellé correspondant au choixEncodage
cmdProgress='zenity --progress --title="$outputFileName" --text="Conversion $libEncodage en cours..." --width=400 --height=40 --no-cancel --auto-close 2>/dev/null'
if [ -z "$withLog" ]; then
	eval "$cmdConv | $cmdProgress"
else
	eval "$cmdConv 2>&1 | tee avconvzen.log | $cmdProgress" # avec log 
fi

# -------------------------------------------------
# ---		Fin du script			---
# -------------------------------------------------
exit

