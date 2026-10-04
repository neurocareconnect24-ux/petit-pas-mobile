import pandas as pd

SEX = {1: 'male', 2: 'female'}
FILES = {'wfa': 'weianthro.dta', 'hfa': 'lenanthro.dta', 'hcfa': 'hcanthro.dta'}

def sample(fname):
    df = pd.read_stata(fname)
    by = {}
    for _, r in df.iterrows():
        by[(int(r['__000001']), int(r['_agedays']))] = (r['l'], r['m'], r['s'])
    out = {}
    for scode, sname in SEX.items():
        rows = {}
        for month in range(0, 61):
            day = round(month * 30.4375)
            l, m, s = by[(scode, day)]
            rows[month] = (round(float(l), 4), round(float(m), 4), round(float(s), 5))
        out[sname] = rows
    return out

lines = []
lines.append("import '../models/child.dart';")
lines.append("import '../models/growth.dart';")
lines.append("")
lines.append("/// Paramètres LMS de la méthode OMS (Box-Cox) : L=asymétrie, M=médiane, S=CV.")
lines.append("/// z = ((valeur/M)^L - 1) / (L * S)   (et z = ln(valeur/M)/S si L≈0)")
lines.append("class LMS {")
lines.append("  final double l;")
lines.append("  final double m;")
lines.append("  final double s;")
lines.append("  const LMS(this.l, this.m, this.s);")
lines.append("}")
lines.append("")
lines.append("/// Tables OFFICIELLES des normes de croissance OMS 2006 (0-5 ans),")
lines.append("/// paramètres L, M, S par mois (0 à 60) et par sexe, pour :")
lines.append("///   wfa  = poids-pour-âge (kg)")
lines.append("///   hfa  = longueur/taille-pour-âge (cm) — longueur < 24 mois, taille ≥ 24 mois")
lines.append("///   hcfa = périmètre crânien-pour-âge (cm)")
lines.append("///")
lines.append("/// Source : WHO Child Growth Standards (igrowup) — fichiers officiels")
lines.append("/// weianthro / lenanthro / hcanthro. Échantillonnés à j = round(mois × 30.4375).")
lines.append("/// NE PAS modifier à la main : régénérer depuis les fichiers OMS.")
lines.append("const Map<String, Map<int, LMS>> whoGrowthLms = {")
for ind, fname in FILES.items():
    data = sample(fname)
    for sname in ('male', 'female'):
        lines.append(f"  '{ind}_{sname}': {{")
        for month, (l, m, s) in data[sname].items():
            lines.append(f"    {month}: LMS({l}, {m}, {s}),")
        lines.append("  },")
lines.append("};")

open('who_growth_data.dart', 'w').write("\n".join(lines) + "\n")
print("Généré:", len(lines), "lignes")
