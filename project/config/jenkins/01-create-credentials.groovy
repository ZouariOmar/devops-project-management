import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
import hudson.slaves.EnvironmentVariablesNodeProperty

def jenkins = Jenkins.get()

def secretsFile = new File("/var/lib/jenkins/mysql.credentials")

// Init scripts run on every start, but the file only exists on the first one
if (!secretsFile.isFile()) {
    println "[JENKINS] No MySQL credentials file, skipping."
    return
}

def lines = secretsFile.readLines("UTF-8")

if (lines.size() < 3 || lines.take(3).any { !it }) {
    throw new IllegalStateException("Invalid MySQL credentials file")
}

def (username, password, url) = lines

// --------------------------------------------------
// Credentials
// --------------------------------------------------

def credentialsId = 'mysql-credentials'

def credential = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    credentialsId,
    'MySQL application user',
    username,
    password
)

def provider = SystemCredentialsProvider.getInstance()
def store = provider.getStore()
def existing = provider.getCredentials().find {
    it.hasProperty('id') && it.id == credentialsId
}

if (existing == null) {
    store.addCredentials(Domain.global(), credential)
} else {
    store.updateCredentials(Domain.global(), existing, credential)
}

// --------------------------------------------------
// Global MYSQL_URL variable
// --------------------------------------------------

def properties = jenkins.getGlobalNodeProperties()
def envProperty = properties.get(EnvironmentVariablesNodeProperty)

if (envProperty == null) {
    envProperty = new EnvironmentVariablesNodeProperty()
    properties.add(envProperty)
}

envProperty.getEnvVars().put('MYSQL_URL', url)

jenkins.save()

if (!secretsFile.delete()) {
    println "[JENKINS] WARNING: Could not delete MySQL credentials file."
}

println "[JENKINS] MySQL credentials configured."
