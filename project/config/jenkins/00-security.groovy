import jenkins.model.Jenkins
import hudson.security.HudsonPrivateSecurityRealm
import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
import hudson.model.User

def instance = Jenkins.get()

def credentialsFile = new File(
    "/var/lib/jenkins/jenkins-admin.credentials"
)

// --------------------------------------------------
// Authentication
// --------------------------------------------------

def realm = instance.getSecurityRealm()

if (!(realm instanceof HudsonPrivateSecurityRealm)) {
    realm = new HudsonPrivateSecurityRealm(false)
    instance.setSecurityRealm(realm)
}

def username = null
def password = null

if (credentialsFile.isFile()) {
    def credentials = credentialsFile.readLines("UTF-8")

    if (credentials.size() < 2 ||
        !credentials[0].trim() ||
        !credentials[1]) {
        throw new IllegalStateException(
            "Invalid Jenkins administrator credentials"
        )
    }

    username = credentials[0].trim()
    password = credentials[1]

    def user = User.getById(username, false)

    if (user == null) {
        realm.createAccount(username, password)
        println "[JENKINS] Administrator created: ${username}"
    } else {
        println "[JENKINS] Administrator already exists: ${username}"
    }
} else {
    throw new IllegalStateException(
        "Missing Jenkins administrator credentials"
    )
}

// --------------------------------------------------
// Authorization
// --------------------------------------------------

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()

strategy.setAllowAnonymousRead(false)

instance.setAuthorizationStrategy(strategy)

// --------------------------------------------------
// Save configuration
// --------------------------------------------------

instance.save()

// --------------------------------------------------
// Credentials cleanup
// --------------------------------------------------

if (credentialsFile.exists()) {
    if (!credentialsFile.delete()) {
        println "[JENKINS] WARNING: Could not delete credentials file."
    } else {
        println "[JENKINS] Temporary credentials file removed."
    }
}

println "[JENKINS] Security configuration completed."
