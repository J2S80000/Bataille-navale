# Configuration Multi-Backend: MongoDB Web + Firebase Android

## Architecture

- **Web (Chrome/Safari)**: Utilise MongoDB local via Docker (27017:27017)
- **Android**: Utilise Firebase (Cloud Firestore + Firebase Auth)
- **Desktop (Windows)**: Firebase (optionnel)

## Démarrage du serveur MongoDB

### Prérequis
- Docker Desktop installé et démarré
- Au moins 2GB d'espace disque libre

### Lancer le conteneur MongoDB

```bash
# À partir du répertoire racine du projet
docker-compose up -d

# Vérifier que les services sont démarrés
docker-compose ps

# Voir les logs
docker-compose logs -f mongodb
```

### Accéder à l'interface MongoDB Express (optionnel)

```
http://localhost:8081
```

### Arrêter les services

```bash
docker-compose down

# Avec suppression des données
docker-compose down -v
```

## Démarrer l'application

### Web (avec MongoDB)

```bash
flutter run -d chrome
# ou
flutter run -d web
```

L'application détectera automatiquement MongoDB sur `http://localhost:27017` et l'utilisera pour persister les statistiques de jeu.

### Android (avec Firebase)

```bash
flutter run -d android
# ou depuis Android Studio
# Build > Build Bundle(s) / APK(s) > Build APK(s)
```

Le code utilisera Firebase Cloud Firestore et Authentication pour synchroniser les données.

## Problèmes courants

### MongoDB n'est pas accessible

1. Vérifier que Docker Desktop est démarré
2. Vérifier que le conteneur est actif:
   ```bash
   docker-compose ps
   ```
3. Redémarrer les services:
   ```bash
   docker-compose restart
   ```

### Port 27017 déjà utilisé

```bash
# Vérifier quel processus utilise le port
netstat -ano | findstr :27017

# Libérer le port (Windows PowerShell en admin)
Stop-Process -Id <PID> -Force

# Ou modifier le port dans docker-compose.yml
# Changer "27017:27017" en "27018:27017"
```

### Donner des permissions réseau sur Windows

Permettre à Docker d'accéder au port:
1. Windows Defender Firewall > Advanced settings
2. Inbound Rules > New Rule
3. Port > TCP > Specific local ports: 27017

## Environnements de développement

### VS Code
```bash
# Terminal intégré
docker-compose up -d
flutter run -d chrome
```

### Android Studio
```bash
# Terminal
docker-compose up -d

# Dans Android Studio: Run > Run (ou Shift+F10)
```

## Architecture du code

- `lib/services/firebase_service.dart`: Détecte `kIsWeb` et utilise MongoDB ou Firebase
- `lib/services/mongodb_service.dart`: Client HTTP pour MongoDB
- `lib/models/statistics.dart`: Sérialisation JSON pour MongoDB
- `docker-compose.yml`: Configuration du serveur MongoDB

## Données persistantes

- Les statistiques de jeu sont sauvegardées dans MongoDB
- Les données survivent à un redémarrage du conteneur
- Pour réinitialiser les données: `docker-compose down -v`

## Performance

- MongoDB local: Requêtes < 10ms
- Pas de latence réseau (localhost)
- Idéal pour le développement

## Production

Pour déployer sur un serveur:

1. Changer `http://localhost:27017` en URL du serveur MongoDB
2. Configurer l'authentification MongoDB
3. Utiliser SSL/TLS pour les connexions
4. Activer les backups automatiques
