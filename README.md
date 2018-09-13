# AVCONVZEN
objet: Conversion de vidéos avec liste de choix possibles (codecs+dimensions) 

dépendances: zenity, avconv

![screenshot](https://github.com/ledudulela/Script_SYS_Avconvzen/blob/master/avconvzen.jpg)

--

Le chemin du fichier cible final sera de la forme: 

   /repertoireFichierSource/nomFichierSource_ancienneExtension_LxH.nouvelleExtension

Exemple:

   /home/user/Vidéos/ma.Video.MPG  -->  /home/user/Vidéos/ma.Video_MPG_640x360.avi

--

utilisation:

dans un terminal, lancez la commande suivante:

avconvzen chemin_du_fichier 

avconvzen -h : affiche l'aide sur les différents paramètres possibles du script

--

remarque: 

Le script est à placer dans le répertoire /usr/local/bin/ 

retirez le .sh ou créez un lien symbolique nommé avconvzen

--

voir aussi:

comment exécuter avconvzen depuis le gestionnaire de fichiers Caja : 
https://github.com/ledudulela/Script_CAJA_Avconvzen

comment exécuter avconvzen depuis le gestionnaire de fichiers Nemo : 
https://github.com/ledudulela/Script_NEMO_Avconvzen
