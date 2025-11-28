# 🧪 Guide de Test - Flux Complet

**Date**: 26 novembre 2025  
**Objectif**: Vérifier que le flux placement → gameplay fonctionne

---

## ✅ Test Rapide

### Étape 1: Lancer l'app
```bash
flutter run
```

### Étape 2: Écran Principal
- ✅ Appuyer sur **"Nouvelle partie vs l'IA"**
- 🔍 Observer les logs dans la console

### Étape 3: Écran de Placement
- ✅ **Console doit afficher**: `📋 Partie créée: game_ai_...`
- ✅ Placer 5 navires (cliquer boutons puis cliquer plateau)
- ✅ Sélectionner orientation (horizontal/vertical)
- 🔍 Affichage en bas: "Navires à placer" doit diminuer de 5 → 0

### Étape 4: Appuyer "Prêt" (✓ en haut à droite)
- 🔍 Console doit afficher:
  ```
  ✅ Placement joueur terminé
     Navires sur plateau: 5
  🤖 Plateau IA généré avec 5 navires
  🎮 Transition vers GameScreen...
  ```

### Étape 5: Écran de Jeu
- ✅ Doit s'afficher automatiquement après "Prêt"
- ✅ Voir deux plateaux: "Mon Plateau" + "Plateau Adversaire"
- ✅ Swiper droite pour voir plateau adversaire
- ✅ Taper sur cellule = tirer
- 🤖 L'IA doit jouer automatiquement après 800ms

---

## 🔴 Problèmes Possibles

### Problème: Rien ne se passe après "Prêt"
**Vérification**:
1. Ouvrir console (terminal)
2. Chercher si un message d'erreur s'affiche
3. Si oui → envoyer le message
4. Si non → le code doit transiter mais sans log

**Solution**: Les logs qu'on vient d'ajouter vont identifier le souci

### Problème: "Placez tous les navires"
- ✅ Cliquer un bouton navire (devient bleu)
- ✅ Cliquer sur le plateau pour placer
- ✅ Navire doit s'afficher en bleu clair sur plateau
- ✅ Bouton doit disparaître du panel

---

## 📊 Logs Attendus (Ordre)

```
🎮 Démarrage partie vs IA
📋 Partie créée: game_ai_1732617600000
   Joueur 1: Champion
   Joueur 2 (IA): IA Expert

[Utilisateur place 5 navires]

✅ Placement joueur terminé
   Navires sur plateau: 5
🤖 Plateau IA généré avec 5 navires
🎮 Transition vers GameScreen...

[Utilisateur tape sur plateau]

🎯 Vérification coup (3, 5):
   isPlayer1Turn: true
   Cell state: empty/ship
   ✅ Cellule valide

🤖 IA joue coup: (7, 4)
[Coup IA résultat...]
```

---

## 📝 Notes Techniques

### Fichiers Modifiés
1. `placement_screen.dart`: 
   - Ajout `Icons.directions_boat_filled`
   - Amélioration `_complete()` avec logs

2. `main_screen.dart`:
   - Logs détaillés dans `_startGameVsAI()`
   - Logs du flux placement → gameplay

### Architecture du Flux
```
MainScreen
  ↓
PlacementScreen (onPlacementComplete callback)
  ↓ [5 navires placés]
  ↓ [appuyer "Prêt"]
  ↓
GameService.generateRandomShipPlacement() [IA]
  ↓
GameScreen (avec boards mis à jour)
  ↓
Gameplay commence
```

---

## ✨ Améliorations Apportées

| Élément | Avant | Après |
|--------|-------|-------|
| **Icône navire** | `directions_boat` ❌ | `directions_boat_filled` ✅ |
| **Logs placement** | Aucun | Détaillés 📝 |
| **Vérification navires** | Silencieuse | Affiche nombre ✅ |
| **Erreur handling** | Crash possible | Try-catch ✅ |
| **Transition** | Peut échouer silencieusement | Logs + erreurs |

---

**Exécutez et reportez les logs de la console!**
