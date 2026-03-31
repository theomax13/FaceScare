# FaceScare — User Stories par Release

---

## RELEASE 1 — MVP : Détection + Scare

> Objectif : valider le concept (le visage proche → scare) avec un premier utilisateur.
> Métrique : l'app scare correctement dans 90% des rapprochements réels, 0 crash.

---

### DELIVERABLE : Détection faciale temps réel

---

#### US 1.1 — Autoriser l'accès à la caméra

> L'utilisateur autorise l'app à utiliser sa webcam.

**Règles :**
- Au tout premier lancement, l'app demande la permission avant toute autre action
- Le message affiché explique pourquoi en langage simple : "FaceScare needs camera access to detect how close your face is to the screen."
- L'app ne fait rien tant que l'utilisateur n'a pas répondu (pas de détection en arrière-plan)

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | L'app est lancée pour la première fois | Le système affiche la popup de permission caméra | L'utilisateur voit le message explicatif et peut choisir "Autoriser" ou "Refuser" |
| 2 | L'utilisateur clique "Autoriser" | La permission est accordée | La détection démarre immédiatement, l'icône 👁️ apparaît dans la barre de menu |
| 3 | L'utilisateur clique "Refuser" | La permission est refusée | Une alerte s'affiche avec deux boutons : "Ouvrir les Réglages" et "Quitter" |
| 4 | L'utilisateur clique "Ouvrir les Réglages" | Les Préférences Système s'ouvrent sur la page Caméra | L'app reste ouverte en arrière-plan et attend |
| 5 | L'utilisateur clique "Quitter" | — | L'app se ferme proprement |
| 6 | L'app est relancée alors que la permission a déjà été accordée | — | Aucune popup, la détection démarre directement |

---

#### US 1.2 — Détecter un visage devant l'écran

> L'app repère qu'un visage est présent devant la webcam.

**Règles :**
- La détection se fait en continu tant que l'app est active
- Si aucun visage n'est visible (utilisateur parti, couvercle du laptop fermé partiellement), rien ne se passe
- L'app ne consomme pas de ressources visibles pour l'utilisateur (pas de ralentissement perceptible)
- La webcam n'affiche aucune prévisualisation à l'écran (pas de fenêtre vidéo)

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | L'utilisateur est assis devant son Mac à distance normale (~60cm) | L'app tourne en arrière-plan | Un visage est détecté, mais aucune action n'est déclenchée (distance correcte) |
| 2 | L'utilisateur quitte son bureau | Personne n'est devant la caméra | Aucun visage détecté, aucune action, aucune erreur |
| 3 | Un poster ou une photo est visible à l'écran | — | Les images fixes ne déclenchent pas de faux positif (seuls les vrais visages 3D sont détectés par Vision) |
| 4 | Deux personnes sont devant l'écran (ex: collègue qui passe derrière) | Deux visages détectés | Seul le visage le plus grand (le plus proche de la caméra) est pris en compte |
| 5 | La luminosité est très faible (bureau sombre) | — | La détection continue de fonctionner (la webcam compense), mais peut être moins fiable — aucun crash |

---

#### US 1.3 — Évaluer la proximité du visage

> L'app mesure si le visage est "trop proche" de l'écran par rapport au seuil défini.

**Règles :**
- La proximité est évaluée par la taille du visage dans l'image : plus le visage est gros, plus l'utilisateur est proche
- Le seuil par défaut est "Medium" : le visage occupe 40% de la largeur de l'image
- Si le visage dépasse ce seuil → l'événement "trop proche" est émis
- Si le visage est en dessous du seuil → rien ne se passe
- L'évaluation se fait sur chaque image capturée par la caméra (plusieurs fois par seconde)

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | Seuil à 40%, l'utilisateur est à ~60cm (visage = 20% de l'image) | L'app évalue la taille du visage | 20% < 40% → rien ne se passe |
| 2 | Seuil à 40%, l'utilisateur se penche à ~25cm (visage = 45% de l'image) | L'app évalue la taille du visage | 45% > 40% → événement "trop proche" déclenché |
| 3 | Seuil à 40%, le visage oscille autour de 39-41% | Le visage passe et repasse le seuil | L'événement se déclenche à chaque franchissement au-dessus (le cooldown empêchera le spam, voir US 1.7) |
| 4 | L'utilisateur porte des lunettes ou un masque | — | La détection fonctionne quand même (Vision détecte les visages partiellement occultés) |

---

### DELIVERABLE : Jump scare dissuasif

---

#### US 1.4 — Jouer un son effrayant

> L'utilisateur entend un son fort et soudain quand il est trop proche.

**Règles :**
- Le son est joué au volume maximum de l'app (indépendant du volume système — si le Mac est en muet, pas de son)
- Un son est choisi au hasard parmi les fichiers disponibles dans l'app
- Le son se joue une seule fois (pas de boucle)
- La durée du son est courte : entre 1 et 3 secondes
- Si aucun fichier son n'est présent dans l'app, un bip système est joué à la place

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | 3 fichiers sons sont disponibles (scare1, scare2, scare3) | Un scare est déclenché | Un des 3 sons est choisi au hasard et joué une fois à volume max |
| 2 | Scare déclenché 2 fois de suite (après cooldown) | — | Le son choisi peut être différent à chaque fois (aléatoire) ou le même (le hasard décide) |
| 3 | Aucun fichier son n'est présent | Un scare est déclenché | Un bip système retentit + un message d'avertissement est affiché dans la console |
| 4 | Le volume système du Mac est à zéro (muet) | Un scare est déclenché | Le son est "joué" mais inaudible — c'est le comportement normal, l'app ne force pas le volume système |
| 5 | Un son est en cours de lecture | Un nouveau scare est déclenché (après cooldown) | Le nouveau son remplace l'ancien (pas de superposition) |

---

#### US 1.5 — Afficher une image effrayante en plein écran

> L'utilisateur voit une image choc qui recouvre tout l'écran pendant un bref instant.

**Règles :**
- L'image `jump-scare.png` est affichée étirée sur tout l'écran principal, fond noir
- L'image apparaît au-dessus de toutes les autres fenêtres (y compris les apps en plein écran)
- L'image reste affichée exactement 500 millisecondes (0,5 seconde) puis disparaît automatiquement
- L'utilisateur ne peut pas cliquer sur l'image (elle ne bloque pas la souris)
- L'image et le son se déclenchent en même temps

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | jump-scare.png est présent dans l'app | Un scare est déclenché | L'image s'affiche plein écran pendant 500ms, le son joue en même temps, puis l'image disparaît |
| 2 | jump-scare.png est absent | Un scare est déclenché | Un écran rouge semi-transparent s'affiche à la place pendant 500ms (fallback) |
| 3 | L'utilisateur est en train de taper au clavier | L'image apparaît | L'utilisateur peut continuer à taper — l'image ne capture pas le focus clavier ni la souris |
| 4 | L'utilisateur a 2 écrans | Un scare est déclenché | L'image s'affiche uniquement sur l'écran principal |
| 5 | L'image est toujours affichée | L'app crashe ou est force-quittée | L'image disparaît (la fenêtre est détruite avec l'app) |

---

#### US 1.6 — Déclencher le scare (son + image ensemble)

> Quand le visage est trop proche, le son et l'image se lancent simultanément.

**Règles :**
- Le scare = son (US 1.4) + image (US 1.5) déclenchés en même temps
- Un scare ne peut être déclenché que si l'app est active (pas désactivée)
- Le scare incrémente un compteur interne (pour les stats futures)
- Si le scare est en cours (image encore affichée), un deuxième scare ne peut pas se superposer

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | L'app est active, l'utilisateur se penche au-delà du seuil | L'événement "trop proche" est émis | Son aléatoire joué + image plein écran 500ms, en même temps |
| 2 | Un scare est en cours (image encore visible) | Un nouvel événement "trop proche" arrive | Le nouvel événement est ignoré |
| 3 | L'app est désactivée (via le menu) | L'utilisateur se penche | Rien ne se passe — aucun scare |
| 4 | Après un scare | — | Le compteur interne passe de N à N+1 |

---

#### US 1.7 — Empêcher les scares répétitifs (cooldown)

> Après un scare, l'app attend un délai avant de pouvoir en déclencher un autre.

**Règles :**
- Le délai par défaut est de 10 secondes
- Pendant ce délai, même si le visage est trop proche, aucun scare n'est déclenché
- Le délai commence au moment exact où le scare se déclenche (pas quand il se termine)
- Si l'utilisateur s'éloigne puis revient pendant le cooldown, le cooldown continue normalement

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | Un scare vient de se déclencher (T=0) | L'utilisateur reste trop proche à T=3s | Rien ne se passe — cooldown actif (3s < 10s) |
| 2 | Un scare s'est déclenché à T=0 | L'utilisateur est trop proche à T=10s | Rien ne se passe — cooldown encore actif (10s = 10s, il faut > 10s) |
| 3 | Un scare s'est déclenché à T=0 | L'utilisateur est trop proche à T=11s | Nouveau scare déclenché — cooldown écoulé |
| 4 | Un scare s'est déclenché à T=0, l'utilisateur s'éloigne à T=2s | L'utilisateur revient trop proche à T=8s | Rien ne se passe — le cooldown ne se réinitialise pas quand le visage s'éloigne |
| 5 | Un scare s'est déclenché à T=0, l'utilisateur s'éloigne à T=2s | L'utilisateur revient trop proche à T=15s | Nouveau scare déclenché |

---

#### US 1.8 — Apparaître dans la barre de menu

> L'app est visible uniquement par une icône dans la barre de menu du Mac (pas dans le Dock).

**Règles :**
- L'icône affichée est 👁️
- L'app n'apparaît pas dans le Dock
- L'app n'a pas de fenêtre principale
- Un clic sur l'icône ouvre un menu déroulant (voir US 1.9)

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | L'app est lancée | — | L'icône 👁️ apparaît dans la barre de menu, rien dans le Dock |
| 2 | L'utilisateur fait Cmd+Tab | — | FaceScare n'apparaît pas dans le sélecteur d'apps |
| 3 | L'utilisateur cherche une fenêtre FaceScare | — | Il n'y en a pas — tout se passe via le menu |

---

#### US 1.9 — Quitter l'application

> L'utilisateur peut fermer l'app depuis le menu.

**Règles :**
- Le menu contient un item "Quit FaceScare" en dernière position
- Le raccourci clavier est ⌘Q
- Quitter l'app arrête la caméra et libère toutes les ressources

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | L'app tourne normalement | L'utilisateur clique sur 👁️ puis "Quit FaceScare" | L'app se ferme, l'icône disparaît de la barre de menu, la caméra s'éteint |
| 2 | L'app tourne normalement | L'utilisateur utilise le raccourci ⌘Q (menu ouvert) | Même résultat |
| 3 | Un scare est en cours (image affichée) | L'utilisateur quitte | L'image disparaît, le son s'arrête, l'app se ferme |

---
---

## RELEASE 2 — Personnalisation + Métriques

> Objectif : l'utilisateur adapte l'app à ses besoins ; mesurer l'impact sur la posture.
> Métrique : 80% des testeurs trouvent un réglage qui leur convient ; scares/jour -50% après 7 jours.

---

### DELIVERABLE : Réglages personnalisables

---

#### US 2.1 — Choisir la sensibilité de détection

> L'utilisateur règle à quel point il doit être proche pour déclencher un scare.

**Règles :**
- 3 choix possibles : "Faible", "Moyenne", "Élevée"
- "Faible" = il faut être très proche pour déclencher (seuil à 50%)
- "Moyenne" = distance raisonnable (seuil à 40%) — choix par défaut
- "Élevée" = se déclenche assez facilement (seuil à 30%)
- Le choix se fait depuis le menu → sous-menu "Sensibilité"
- Le choix actuel est coché dans le menu
- Le changement prend effet immédiatement (pas besoin de relancer l'app)

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | Sensibilité sur "Moyenne" (défaut) | L'utilisateur ouvre le menu Sensibilité | "Moyenne (40%)" est coché, les 2 autres ne le sont pas |
| 2 | Sensibilité sur "Moyenne" | L'utilisateur choisit "Élevée" | La coche passe sur "Élevée", le scare se déclenche maintenant à 30% — plus sensible |
| 3 | Sensibilité sur "Élevée" | L'utilisateur est à ~50cm du Mac (visage = 32%) | Scare déclenché (32% > 30%) |
| 4 | Sensibilité sur "Faible" | L'utilisateur est à ~50cm du Mac (visage = 32%) | Rien ne se passe (32% < 50%) |
| 5 | L'utilisateur change de sensibilité pendant une détection | — | La nouvelle sensibilité s'applique dès la prochaine évaluation, aucune interruption |

---

#### US 2.2 — Choisir le délai entre les scares

> L'utilisateur règle combien de temps l'app attend entre deux scares.

**Règles :**
- 4 choix possibles : 5 secondes, 10 secondes, 20 secondes, 30 secondes
- 10 secondes par défaut
- Le choix se fait depuis le menu → sous-menu "Cooldown"
- Le choix actuel est coché dans le menu
- Le changement prend effet immédiatement

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | Cooldown à 10s (défaut) | L'utilisateur ouvre le menu Cooldown | "10s" est coché |
| 2 | Cooldown à 10s | L'utilisateur choisit "5s" | La coche passe sur "5s", le prochain cooldown sera de 5s |
| 3 | Un scare vient de se déclencher, l'utilisateur change le cooldown de 10s à 30s | — | Le nouveau cooldown de 30s s'applique à partir de maintenant (le cooldown en cours est remplacé) |
| 4 | Cooldown à 5s | 2 scares en 6s sont-ils possibles ? | Oui : scare à T=0, scare à T=6s (6 > 5) |

---

#### US 2.3 — Activer ou désactiver l'app

> L'utilisateur met la détection en pause ou la réactive.

**Règles :**
- Un item dans le menu affiche "Désactiver" quand l'app est active, "Activer" quand elle est en pause
- Raccourci clavier : ⌘D
- Quand l'app est désactivée : la caméra s'arrête, l'icône change (👁️ → 👁️‍🗨️)
- Quand l'app est réactivée : la caméra redémarre, l'icône revient (👁️‍🗨️ → 👁️)
- Désactiver ne quitte pas l'app (elle reste dans la barre de menu)

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | L'app est active | L'utilisateur clique "Désactiver" | L'icône passe à 👁️‍🗨️, la caméra s'arrête, le menu affiche maintenant "Activer", plus aucun scare possible |
| 2 | L'app est désactivée | L'utilisateur se penche vers l'écran | Rien ne se passe (la caméra est éteinte) |
| 3 | L'app est désactivée | L'utilisateur clique "Activer" | L'icône revient à 👁️, la caméra redémarre, la détection reprend |
| 4 | L'app est active | L'utilisateur tape ⌘D (menu ouvert) | Même effet que cliquer "Désactiver" |
| 5 | L'app est désactivée puis réactivée | — | Le compteur de scares n'est pas réinitialisé (il garde son historique) |

---

### DELIVERABLE : Personnalisation du scare

---

#### US 2.4 — Changer l'image du jump scare

> L'utilisateur remplace l'image effrayante par celle de son choix.

**Règles :**
- L'utilisateur dépose un fichier nommé `jump-scare.png` dans le dossier Resources de l'app
- L'image est chargée à chaque scare (pas mise en cache au lancement) — ainsi le changement est pris en compte sans relancer l'app
- Formats acceptés : PNG uniquement
- Si le fichier est absent ou illisible → l'écran rouge de fallback s'affiche

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | L'utilisateur a remplacé jump-scare.png par une photo de clown | Un scare se déclenche | La photo de clown s'affiche en plein écran pendant 500ms |
| 2 | L'utilisateur a supprimé jump-scare.png | Un scare se déclenche | L'écran rouge semi-transparent s'affiche en fallback |
| 3 | L'utilisateur a mis un fichier corrompu (0 octets) | Un scare se déclenche | L'écran rouge s'affiche en fallback, pas de crash |
| 4 | L'utilisateur a mis un fichier .jpg renommé en .png | Un scare se déclenche | L'image s'affiche quand même si macOS arrive à la lire, sinon fallback rouge |

---

#### US 2.5 — Ajouter ses propres sons

> L'utilisateur ajoute des fichiers sons pour varier les scares.

**Règles :**
- L'app cherche tous les fichiers dont le nom commence par "scare" et finit par ".mp3" dans le dossier Resources
- Le choix du son est aléatoire à chaque scare parmi tous les fichiers trouvés
- Il faut au moins 1 fichier son — sinon bip système en fallback
- Pas de limite maximale du nombre de fichiers

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | L'utilisateur a ajouté scare4.mp3 et scare5.mp3 (5 fichiers au total) | Scare déclenché | Un des 5 sons est choisi au hasard |
| 2 | Un seul fichier : scare1.mp3 | Scare déclenché | Toujours scare1.mp3 |
| 3 | L'utilisateur a supprimé tous les fichiers son | Scare déclenché | Bip système + message console "[FaceScare] Aucun fichier son trouvé" |
| 4 | L'utilisateur a ajouté un fichier "mysound.mp3" (ne commence pas par "scare") | Scare déclenché | Ce fichier est ignoré — seuls les fichiers "scare*.mp3" sont pris en compte |

---

### DELIVERABLE : Compteur de scares

---

#### US 2.6 — Voir le nombre de scares de la session

> L'utilisateur consulte combien de scares se sont déclenchés depuis le lancement de l'app.

**Règles :**
- Le compteur apparaît dans le menu déroulant, en texte grisé (non cliquable)
- Format : "Scares déclenchés : X"
- Le compteur se met à jour à chaque ouverture du menu
- Le compteur repart à 0 quand l'app est relancée

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | L'app vient d'être lancée, aucun scare | L'utilisateur ouvre le menu | "Scares déclenchés : 0" |
| 2 | 7 scares déclenchés dans la session | L'utilisateur ouvre le menu | "Scares déclenchés : 7" |
| 3 | 3 scares déclenchés, l'utilisateur quitte et relance l'app | L'utilisateur ouvre le menu | "Scares déclenchés : 0" (pas de persistance en Release 2) |
| 4 | Un scare se déclenche pendant que le menu est ouvert | — | Le compteur affiche toujours l'ancienne valeur, il se mettra à jour à la prochaine ouverture du menu |

---
---

## RELEASE 3 — Viralité + Entreprise

> Objectif : 10 utilisateurs externes, 1 déploiement équipe testé.
> Métrique : 10 installations mois 1 ; rétention >5j/7 chez 60% des utilisateurs.

---

### DELIVERABLE : Expérience prank partageable

---

#### US 3.1 — Exporter ses stats en image

> L'utilisateur génère une image résumant ses stats pour la partager avec ses collègues.

**Règles :**
- Un item "Partager mes stats" apparaît dans le menu
- L'image générée est un PNG contenant : nombre de scares aujourd'hui, tendance sur 7 jours, meilleur jour
- L'image est copiée dans le presse-papier (prête à coller dans Slack, Teams, etc.)
- Aucune donnée personnelle identifiable (pas de nom, pas de photo)

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | 2 scares aujourd'hui, tendance en baisse sur 7j | L'utilisateur clique "Partager mes stats" | Image générée et copiée dans le presse-papier avec le texte "Jour 5 : seulement 2 scares ! En progrès." |
| 2 | L'utilisateur colle dans Slack | — | L'image PNG apparaît directement dans le message |
| 3 | Aucune donnée historique (premier jour) | L'utilisateur clique "Partager mes stats" | Image simplifiée : "Jour 1 : X scares — c'est parti !" |

---

#### US 3.2 — Installer l'app discrètement (mode prank)

> Un collègue peut installer l'app sur le Mac d'un autre sans que ce soit évident.

**Règles :**
- L'app ne montre aucune fenêtre au démarrage
- L'icône 👁️ est discrète dans la barre de menu (pas de bounce dans le Dock, pas de notification)
- La permission caméra reste obligatoire (imposé par Apple) — c'est le seul indice visible

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | L'app est installée et lancée sur le Mac d'un collègue | Le collègue regarde son écran | Il voit uniquement 👁️ dans la barre de menu — facile à rater |
| 2 | Le collègue se penche vers son écran | — | Scare déclenché ! Surprise. |
| 3 | Le collègue veut comprendre d'où ça vient | Il clique sur 👁️ | Il découvre le menu FaceScare et peut désactiver ou quitter |

---

### DELIVERABLE : Score ergonomique individuel

---

#### US 3.3 — Voir son score ergonomique

> L'utilisateur voit une note reflétant la qualité de sa posture sur les 7 derniers jours.

**Règles :**
- Score de 0 (mauvaise posture constante) à 100 (aucun scare en 7 jours)
- Affiché dans le menu : "Score ergo : 85/100 ⬆️"
- La flèche indique la tendance : ⬆️ (amélioration), ⬇️ (dégradation), ➡️ (stable)
- Le calcul est basé sur la moyenne glissante de scares/jour sur 7 jours
- Les données sont sauvegardées localement entre les sessions

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | 0 scares sur les 7 derniers jours | L'utilisateur ouvre le menu | "Score ergo : 100/100 ⬆️" |
| 2 | Moyenne de 15 scares/jour sur 7 jours | L'utilisateur ouvre le menu | "Score ergo : 12/100 ⬇️" |
| 3 | Hier 10 scares, aujourd'hui 3 | L'utilisateur ouvre le menu | Le score monte par rapport à hier, flèche ⬆️ |
| 4 | Premier jour d'utilisation, pas encore 7 jours de données | L'utilisateur ouvre le menu | "Score ergo : --/100" (données insuffisantes) |
| 5 | L'utilisateur désactive l'app pendant 3 jours puis la réactive | — | Les jours désactivés comptent comme 0 scares (bon score), puisque l'app n'a pas détecté de mauvaise posture |

---

### DELIVERABLE : Rapport collectif anonymisé

---

#### US 3.4 — Générer un rapport hebdomadaire d'équipe

> Le manager exporte un rapport résumant les scares de toute l'équipe sur la semaine.

**Règles :**
- Bouton "Exporter rapport semaine" dans le menu
- Format : fichier CSV sauvegardé sur le Bureau
- Colonnes : Jour, Nombre de scares (données locales de cette machine uniquement en v3)
- Aucun nom d'utilisateur — l'identifiant est un hash anonyme
- Le rapport couvre les 7 derniers jours

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | 7 jours de données disponibles | L'utilisateur clique "Exporter rapport semaine" | Un fichier `facescare-rapport-2026-W14.csv` est créé sur le Bureau |
| 2 | Moins de 7 jours de données | L'utilisateur exporte | Le rapport contient uniquement les jours disponibles |
| 3 | Le fichier existe déjà sur le Bureau | L'utilisateur exporte à nouveau | Le fichier est écrasé par la nouvelle version |

---

### DELIVERABLE : Distribution simplifiée

---

#### US 3.5 — Installer l'app sans alerte de sécurité

> Le manager IT distribue l'app et les utilisateurs peuvent l'installer sans message "app non vérifiée".

**Règles :**
- L'app est empaquetée dans un fichier .dmg
- Le .dmg contient l'app et un raccourci vers le dossier Applications
- L'app est signée avec un certificat Apple Developer ID
- L'app est notarisée auprès d'Apple (vérification Gatekeeper OK)

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | L'utilisateur télécharge FaceScare.dmg | Il double-clique sur le .dmg | Une fenêtre s'ouvre avec l'icône FaceScare et le dossier Applications |
| 2 | L'utilisateur glisse FaceScare dans Applications | Il lance l'app | L'app démarre sans aucune alerte Gatekeeper ("app non vérifiée") |
| 3 | Le Mac est configuré pour "App Store uniquement" | L'utilisateur lance FaceScare | macOS demande une confirmation mais ne bloque pas (grâce à la notarisation) |

---

#### US 3.6 — Préconfigurer les réglages pour l'équipe

> Le manager IT définit les réglages par défaut avant de déployer l'app.

**Règles :**
- Un fichier `defaults.plist` peut être placé à côté de l'app
- Clés reconnues : sensibilité (faible/moyenne/élevée), cooldown (5/10/20/30), démarrage automatique (oui/non)
- Si le fichier est absent → les valeurs par défaut du code s'appliquent (moyenne, 10s, oui)
- Les réglages du fichier ne sont lus qu'au premier lancement (ensuite l'utilisateur peut les changer)

**Scénarios :**

| # | Given | When | Then |
|---|-------|------|------|
| 1 | defaults.plist présent avec sensibilité=élevée, cooldown=5 | Premier lancement | L'app démarre avec sensibilité Élevée et cooldown 5s |
| 2 | defaults.plist absent | Premier lancement | L'app démarre avec sensibilité Moyenne et cooldown 10s |
| 3 | defaults.plist présent, l'utilisateur change la sensibilité dans le menu | — | Le choix de l'utilisateur est respecté, le fichier n'est plus consulté |
| 4 | defaults.plist contient une valeur invalide (ex: sensibilité="ultra") | Premier lancement | La valeur invalide est ignorée, la valeur par défaut (Moyenne) est utilisée |
