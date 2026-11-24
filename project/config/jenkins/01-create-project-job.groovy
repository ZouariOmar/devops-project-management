import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.BranchSpec
import hudson.plugins.git.UserRemoteConfig

def jenkins = Jenkins.get()

def jobName = 'devops-project-management-job'

def repository =
    'https://github.com/ZouariOmar/devops-project-management'

def job = jenkins.getItem(jobName)

def isNew = (job == null)

// --------------------------------------------------
// Create Pipeline Job
// --------------------------------------------------

if (isNew) {
    job = jenkins.createProject(
        WorkflowJob,
        jobName
    )

    println "[JENKINS] Pipeline job created: ${jobName}"
}

// --------------------------------------------------
// Configure Git Repository
// --------------------------------------------------

def scm = new GitSCM(
    [
        new UserRemoteConfig(
            repository,
            null,
            null,
            null
        )
    ],
    [
        new BranchSpec('*/main')
    ],
    false,
    [],
    null,
    null,
    []
)

// --------------------------------------------------
// Configure Jenkinsfile
// --------------------------------------------------

def pipeline = new CpsScmFlowDefinition(
    scm,
    'Jenkinsfile'
)

pipeline.setLightweight(true)

job.setDefinition(pipeline)

job.setDescription(
    'CI/CD Pipeline for the Spring Boot + Angular application.'
)

job.save()

// --------------------------------------------------
// Initial Build
// --------------------------------------------------

if (isNew) {
    job.scheduleBuild2(0)
}

jenkins.save()

println "[JENKINS] Pipeline configured: ${jobName}"
