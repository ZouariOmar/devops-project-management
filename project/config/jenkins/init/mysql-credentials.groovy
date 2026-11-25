// =================================================================================
// .FILE
//   mysql-credentials.groovy
//
// .SYNOPSIS
//   Configure the MySQL credentials and URL
//
// .DESCRIPTION
//   Creates or updates the `mysql-credentials` entry and the global MYSQL_URL
//   variable, then deletes the secrets file. Skips if the file is missing.
//   Runs as `01-mysql-credentials.groovy`.
//
// .PARAMETER
//   N/A
//
// .INPUTS
//   /var/lib/jenkins/mysql.credentials (user, password, URL).
//
// .OUTPUTS
//   Jenkins credential and global environment variable.
//
// .NOTES
//   Version       : 1.0
//   Author        : @ZouariOmar (zouariomar20@gmail.com)
//   Created       : 2026-11-25
//   Changelog     : e1e38b7
// =================================================================================

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
