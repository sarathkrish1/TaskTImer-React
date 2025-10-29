<#
PowerShell helper to create Jenkins credentials and a pipeline job via the Jenkins CLI.
Usage examples:
  # Interactive (prompts for admin credentials):
  .\setup-jenkins.ps1

  # Non-interactive (use environment variables or pass parameters):
  $env:JENKINS_AUTH = 'admin:2fcce7a4d98f4d6ba46ec50591d63cde'
  .\setup-jenkins.ps1 -JenkinsUrl http://localhost:8082

Notes:
- Requires Java installed and available on PATH.
- Requires a local file `jenkins-kubeconfig.yaml` in the repo root.
- If `jenkins-cli.jar` is not present, the script will attempt to download it from $JenkinsUrl/jnlpJars/jenkins-cli.jar.
- The script creates 3 files in the current folder: kubeconfig-cred.xml, docker-cred.xml, job-config.xml.
- It then uses the Jenkins CLI to create credentials and the job. You can inspect/modify the created XML files before running the CLI if you want.
#>

param(
    [string]$JenkinsUrl = $(if ($env:JENKINS_URL) { $env:JENKINS_URL } else { 'http://localhost:8082' }),
    [string]$Auth = $(if ($env:JENKINS_AUTH) { $env:JENKINS_AUTH } else { '' }),
    [switch]$ForceDownloadCli
)

function Abort($msg){ Write-Error $msg; exit 1 }

Write-Host "Using Jenkins URL: $JenkinsUrl"

# Get auth if not provided
if (-not $Auth) {
    $username = Read-Host "Jenkins username (admin)"
    $pwd = Read-Host "Jenkins password or API token" -AsSecureString
  $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd)
  $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  # Use explicit concatenation to avoid PowerShell parsing issues when the string contains ':'
  $Auth = $username + ":" + $plain
}

# Check Java
try { & java -version > $null 2>&1 } catch { Abort 'Java is required and was not found in PATH. Please install OpenJDK 11+ and try again.' }

# Ensure jenkins-kubeconfig.yaml exists
$kubePath = Join-Path $PSScriptRoot '..\jenkins-kubeconfig.yaml' | Resolve-Path -ErrorAction SilentlyContinue
if (-not $kubePath) { $kubePath = Join-Path $PSScriptRoot 'jenkins-kubeconfig.yaml' }
if (-not (Test-Path $kubePath)) { Abort "Could not find 'jenkins-kubeconfig.yaml' near script path ($kubePath). Place your kubeconfig file there and re-run." }

# Ensure jenkins-cli.jar exists or download it
$cliJar = Join-Path $PSScriptRoot 'jenkins-cli.jar'
if (-not (Test-Path $cliJar) -or $ForceDownloadCli) {
    $downloadUrl = "$JenkinsUrl/jnlpJars/jenkins-cli.jar"
    Write-Host "Downloading jenkins-cli.jar from $downloadUrl"
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $cliJar -UseBasicParsing -ErrorAction Stop
    } catch {
        Abort "Failed to download jenkins-cli.jar from $downloadUrl - $_"
    }
}

if (-not (Test-Path $cliJar)) { Abort 'jenkins-cli.jar still missing after download attempt.' }

# Build XML files
Write-Host 'Creating credential/job XML files...'

# kubeconfig file credential (FileCredentialsImpl uses secretBytes)
$kubeBytes = [Convert]::ToBase64String([IO.File]::ReadAllBytes($kubePath))
$kubeXml = @"
<com.cloudbees.plugins.credentials.impl.FileCredentialsImpl plugin=\"file-credentials@1.4\">
  <scope>GLOBAL</scope>
  <id>kubeconfig</id>
  <description>jenkins kubeconfig for pipeline (uploaded by script)</description>
  <fileName>jenkins-kubeconfig.yaml</fileName>
  <secretBytes>$kubeBytes</secretBytes>
</com.cloudbees.plugins.credentials.impl.FileCredentialsImpl>
"@
$kubeXmlPath = Join-Path $PSScriptRoot 'kubeconfig-cred.xml'
Set-Content -Path $kubeXmlPath -Value $kubeXml -Encoding UTF8

# Placeholder Docker credential
$dockerXml = @"
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>dockerhub-creds</id>
  <description>Placeholder Docker Hub credentials - replace or update via Jenkins UI</description>
  <username></username>
  <password></password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
"@
$dockerXmlPath = Join-Path $PSScriptRoot 'docker-cred.xml'
Set-Content -Path $dockerXmlPath -Value $dockerXml -Encoding UTF8

# Pipeline job config (pulls Jenkinsfile from repo)
$jobXml = @"
<flow-definition plugin=\"workflow-job@2.46\">
  <description>Blue-Green deployment pipeline for Timer App</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class=\"org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition\" plugin=\"workflow-cps@2.93\">
    <scm class=\"hudson.plugins.git.GitSCM\" plugin=\"git@4.15.0\">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/tharunK03/TaskTImer-React.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class=\"list\"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
"@
$jobXmlPath = Join-Path $PSScriptRoot 'job-config.xml'
Set-Content -Path $jobXmlPath -Value $jobXml -Encoding UTF8

# Helper to run jenkins-cli with auth
function Invoke-JenkinsCli([string]$Args) {
  # Build full command and run via cmd.exe so shell redirection (<, |) works as expected
  $authArg = "-auth $Auth"
  $javaCmd = "java -jar `"$cliJar`" -s $JenkinsUrl $authArg $Args"
  $cmdLine = "/c " + $javaCmd
  Write-Host "Running via cmd.exe: $javaCmd"
  $proc = Start-Process -FilePath cmd.exe -ArgumentList $cmdLine -NoNewWindow -Wait -PassThru
  return $proc.ExitCode
}

# Create credentials and job
Write-Host 'Creating kubeconfig credential...'
$exit = Invoke-JenkinsCli "create-credentials-by-xml system::system::jenkins _ < `"$kubeXmlPath`""
if ($exit -ne 0) { Write-Warning "create-credentials-by-xml returned exit code $exit. You may need to run the command manually or check Jenkins permissions." }

Write-Host 'Creating docker placeholder credential...'
$exit = Invoke-JenkinsCli "create-credentials-by-xml system::system::jenkins _ < `"$dockerXmlPath`""
if ($exit -ne 0) { Write-Warning "create-credentials-by-xml (docker) returned exit code $exit. You may need to create/update this credential in the Jenkins UI." }

Write-Host 'Creating pipeline job (timer-app-deployment)...'
$exit = Invoke-JenkinsCli "create-job timer-app-deployment < `"$jobXmlPath`""
if ($exit -ne 0) { Write-Warning "create-job returned exit code $exit. If job already exists update it via UI or use update-job." }

Write-Host 'Listing jobs to verify creation:'
Invoke-JenkinsCli "list-jobs | findstr /C:timer-app-deployment"

Write-Host "Script finished. If any CLI steps failed, open Jenkins UI ($JenkinsUrl) and validate credentials and the job 'timer-app-deployment'."
Write-Host "Remember to update 'dockerhub-creds' in Jenkins UI with real Docker registry credentials."
