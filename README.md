# AVCONVZEN
objet: Conversion de vidéos avec liste de choix possibles (codecs+dimensions) 

dépendances: zenity, avconv

--

Le chemin du fichier cible final sera de la forme: 

   /repertoireFichierSource/nomFichierSource_ancienneExtension_LxH.nouvelleExtension

Exemple:

   /home/user/Vidéos/ma.Video.MPG  -->  /home/user/Vidéos/ma.Video_MPG_640x360.avi

--

utilisation:

avconvzen chemin_du_fichier 

avconvzen -h : affiche l'aide sur les différents paramètres possibles du script

--

remarque: 

Le script est à placer dans le répertoire /usr/local/bin/ 

retirez le .sh ou créez un lien symbolique nommé avconvzen

