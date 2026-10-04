# Génération des tables de croissance OMS

Ce dossier régénère `lib/data/who_growth_data.dart` (paramètres LMS OMS 2006, 0–60 mois).

## Fichiers sources (officiels, versionnés ici)
- `weianthro.dta` — poids-pour-âge (wfa)
- `lenanthro.dta` — longueur/taille-pour-âge (hfa)
- `hcanthro.dta`  — périmètre crânien-pour-âge (hcfa)

Source : dépôt officiel OMS `unicef-drp/igrowup_update`
(`https://raw.githubusercontent.com/unicef-drp/igrowup_update/master/<fichier>.dta`).

## Régénérer
```bash
cd tool/who_growth
python3 -m venv venv && ./venv/bin/pip install pandas
./venv/bin/python generate_who_growth.py   # écrit who_growth_data.dart ici
# puis comparer / copier vers ../../lib/data/who_growth_data.dart
```

## Notes
- Échantillonnage : `jour = round(mois × 30.4375)`.
- Validation : garçon J0 poids `LMS(0.3487, 3.3464, 0.14602)`, garçon 12 mois M=9.646.
- Le fichier Dart du projet ajoute une fonction `whoKey(indicator, sex)` en fin de
  fichier — la conserver après régénération (le script ne la produit pas).
- Pour ajouter poids-pour-taille (wfl/wfh) ou IMC-pour-âge : télécharger les `.dta`
  correspondants et étendre `FILES` dans le script.
