#!/usr/bin/env python3
"""
generate_flyer_gemini.py
────────────────────────
Génère automatiquement un flyer HTML SAMA via l'API Google Gemini.

Usage :
  python generate_flyer_gemini.py --api-key <GEMINI_API_KEY> [options]

Options :
  --api-key       Clé API Gemini (ou variable d'env GEMINI_API_KEY)
  --service       Nom du service  [défaut : "Sama Commande"]
  --emoji         Emoji principal  [défaut : 🛒]
  --routes        Routes séparées par virgule  [défaut : "Paris→Casablanca,Paris→Dakar"]
  --deadline      Texte de la date limite  [défaut : "cette semaine"]
  --message       Message libre supplémentaire (optionnel)
  --output        Fichier de sortie  [défaut : flyer_generated.html]
  --model         Modèle Gemini  [défaut : gemini-1.5-pro]

Exemples :
  python generate_flyer_gemini.py --api-key AIza... \\
      --service "Sama GP" --emoji "✈️" \\
      --routes "Paris→Dakar" \\
      --deadline "vendredi 12 avril" \\
      --output flyer_gp_avril.html

  # Avec variable d'environnement :
  export GEMINI_API_KEY=AIza...
  python generate_flyer_gemini.py --routes "Paris→Casablanca,Paris→Dakar" \\
      --deadline "dimanche 14 avril à minuit" \\
      --message "Profitez du tarif groupage avant départ !"
"""

import argparse
import os
import sys
import textwrap

# ── Dépendance : pip install google-generativeai ──────────────────────────────
try:
    import google.generativeai as genai
except ImportError:
    print(
        "❌  Dépendance manquante.\n"
        "    Installez-la avec :  pip install google-generativeai\n",
        file=sys.stderr,
    )
    sys.exit(1)


# ── Référence HTML (charte graphique SAMA) ───────────────────────────────────
REFERENCE_CSS_SNIPPET = """
  /* Charte SAMA — couleurs de référence */
  --sama-dark-bg  : #1a0a2e;
  --sama-mid-bg   : #2d1b69;
  --sama-pink     : #FF6B9D;
  --sama-purple   : #C850C0;
  --sama-gold     : #FFD700;
  --sama-orange   : #FF8C00;
  --sama-red      : #FF4444;
  --sama-green    : #4ADE80;
  font-family     : 'Poppins', Arial, sans-serif;  /* Google Fonts */
  width           : 794px;   /* format A4 paysage flyer */
  min-height      : 1123px;  /* format A4 portrait */
"""


def build_prompt(service: str, emoji: str, routes: list[str],
                 deadline: str, extra_message: str) -> str:
    """Construit le prompt envoyé à Gemini."""
    routes_str = "\n".join(f"  • {r}" for r in routes)
    extra_block = f"\nMessage additionnel à inclure :\n  « {extra_message} »" if extra_message else ""

    return textwrap.dedent(f"""
    Tu es un expert en design web et communication marketing.

    Génère un fichier HTML **complet et autonome** (CSS inline dans <style>) pour un flyer
    promotionnel de la société SAMA (Ngom Holding Transport & Logistics).

    ═══════════════════ CONTEXTE ═══════════════════
    Service concerné : {emoji} {service}
    Routes / départs :
{routes_str}
    Clôture des commandes : {deadline}
    Site web               : https://www.sama-services-intl.com/commande
    Contact                : tech@ngom-holding.com{extra_block}

    ═══════════════════ CHARTE GRAPHIQUE ════════════
    {REFERENCE_CSS_SNIPPET}
    - Fond sombre dégradé violet/bleu nuit
    - Accent bar dégradé (rouge → orange → or) sur urgence
    - Bandeau d'urgence rouge clignotant (@keyframes pulse)
    - Cards de route : drapeau 🗼 → 🕌 / 🇸🇳, flèche ✈️
    - Boîte deadline ⏳ avec bordure rouge et fond semi-transparent
    - CTA rose/violet avec l'URL du service
    - Footer sombre : "Ngom Holding Transport & Logistics" + email
    - Police Google Fonts Poppins (400/600/700/900)

    ═══════════════════ CONTRAINTES ════════════════
    1. Format A4 portrait : width 794 px, min-height 1123 px
    2. Responsive : @media print (border-radius:0, width:100%)
    3. Pas de JavaScript, pas d'images externes (sauf Google Fonts)
    4. Uniquement des emojis Unicode comme icônes
    5. Texte en français, ton dynamique et urgent
    6. Le HTML doit être prêt à ouvrir dans un navigateur et imprimer
    7. Retourne UNIQUEMENT le code HTML complet, sans aucun commentaire en dehors du HTML

    ═══════════════════ STRUCTURE ATTENDUE ══════════
    <accent-bar>            gradient urgence
    <urgency-ribbon>        bandeau rouge clignotant
    <header>                badge service + titre + sous-titre
    <routes>                1 card par route (drapeau + ville + badge "Départ imminent")
    <deadline-box>          explication clôture + date
    <why-grid>              4 arguments pour commander maintenant
    <cta>                   URL + note WhatsApp
    <footer>                marque + email
    """).strip()


def generate(api_key: str, model_name: str, prompt: str) -> str:
    """Appelle l'API Gemini et retourne le HTML généré."""
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(model_name)

    response = model.generate_content(
        prompt,
        generation_config=genai.types.GenerationConfig(
            temperature=0.4,
            max_output_tokens=8192,
        ),
    )
    return response.text


def extract_html(raw: str) -> str:
    """Extrait le bloc HTML si Gemini l'a entouré de backticks."""
    import re
    # Gemini retourne parfois ```html ... ``` ou ``` ... ```
    match = re.search(r"```(?:html)?\s*(<!DOCTYPE.*?</html>)\s*```", raw, re.DOTALL | re.IGNORECASE)
    if match:
        return match.group(1).strip()
    # Si pas de balises, on cherche juste le début du DOCTYPE
    if "<!DOCTYPE" in raw:
        start = raw.index("<!DOCTYPE")
        return raw[start:].strip()
    return raw.strip()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Génère un flyer HTML SAMA avec l'API Google Gemini",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--api-key",  default=os.environ.get("GEMINI_API_KEY", ""),
                        help="Clé API Gemini (ou variable GEMINI_API_KEY)")
    parser.add_argument("--service",  default="Sama Commande",
                        help="Nom du service (ex: 'Sama GP')")
    parser.add_argument("--emoji",    default="🛒",
                        help="Emoji principal du service")
    parser.add_argument("--routes",   default="Paris→Casablanca,Paris→Dakar",
                        help="Routes séparées par virgule")
    parser.add_argument("--deadline", default="cette semaine",
                        help="Texte de la date limite de commande")
    parser.add_argument("--message",  default="",
                        help="Message libre supplémentaire (optionnel)")
    parser.add_argument("--output",   default="flyer_generated.html",
                        help="Fichier HTML de sortie")
    parser.add_argument("--model",    default="gemini-1.5-pro",
                        help="Modèle Gemini à utiliser")

    args = parser.parse_args()

    if not args.api_key:
        print(
            "❌  Clé API Gemini manquante.\n"
            "    Passez --api-key ou définissez la variable GEMINI_API_KEY.\n",
            file=sys.stderr,
        )
        sys.exit(1)

    routes = [r.strip() for r in args.routes.split(",") if r.strip()]

    print(f"🤖  Modèle      : {args.model}")
    print(f"🛒  Service     : {args.emoji} {args.service}")
    print(f"✈️   Routes      : {', '.join(routes)}")
    print(f"⏳  Deadline    : {args.deadline}")
    print(f"📄  Sortie      : {args.output}")
    print()
    print("⏳  Appel à l'API Gemini en cours…")

    prompt = build_prompt(args.service, args.emoji, routes, args.deadline, args.message)
    raw = generate(args.api_key, args.model, prompt)
    html = extract_html(raw)

    output_path = os.path.join(os.path.dirname(__file__), args.output)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"✅  Flyer généré avec succès : {output_path}")
    print(f"    Ouvrez-le dans votre navigateur, puis File → Print → Save as PDF")


if __name__ == "__main__":
    main()
