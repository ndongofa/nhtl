# 🚀 NHTL Backend – Démarrage en local (Profil `dev` avec H2)

## 1. Pré-requis
- Java 17
- Maven 3.8+
- Spring Boot 3.2.0
- Postman (ou équivalent)

## 2. Configuration Maven
Le profil `dev` ajoute H2 au runtime :

<profiles>
    <profile>
        <id>dev</id>
        <dependencies>
            <dependency>
                <groupId>com.h2database</groupId>
                <artifactId>h2</artifactId>
                <scope>runtime</scope>
            </dependency>
        </dependencies>
    </profile>
</profiles>

## 3. Configuration Spring Boot
Dans `src/main/resources/application-dev.properties` :

server.port=8080
spring.datasource.url=jdbc:h2:mem:nhtldb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console

## 4. Commande de lancement
mvn spring-boot:run -Pdev -Dspring-boot.run.profiles=dev

- -Pdev → active le profil Maven (ajoute H2 au classpath).
- -Dspring-boot.run.profiles=dev → active le profil Spring Boot (utilise application-dev.properties).

## 5. Vérification
- API : http://localhost:8080/api/users
- Console H2 : http://localhost:8080/h2-console
  - JDBC URL : jdbc:h2:mem:nhtldb
  - User : sa
  - Password : (vide)

## 6. Données de test (Postman)

### Créer un utilisateur
POST http://localhost:8080/api/users
Content-Type: application/json

{
  "name": "Alice",
  "email": "alice@example.com",
  "role": "admin"
}

### Lister les utilisateurs
GET http://localhost:8080/api/users

### Modifier un utilisateur
PUT http://localhost:8080/api/users/1
Content-Type: application/json

{
  "name": "Alice Dupont",
  "email": "alice.dupont@example.com",
  "role": "user"
}

### Supprimer un utilisateur
DELETE http://localhost:8080/api/users/1

## 7. Résultat attendu
- L’application démarre sans erreur.
- La base H2 est initialisée automatiquement.
- Les endpoints CRUD User fonctionnent et peuvent être testés via Postman.
- À chaque redémarrage, la base est réinitialisée (utile pour les tests rapides).
