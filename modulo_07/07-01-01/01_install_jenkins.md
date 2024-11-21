# Instalación desatendida de Jenkins
Podemos hacer la instalación de Jenkins automáticamente usando un script bash. El enfoque propuesto está casi completo, pero puede mejorarse para hacerlo más robusto y totalmente desatendido:

~~~sh
cat <<'EOT' > install.sh
#!/bin/bash
# Actualizar paquetes
sudo apt-get update

# Instalar Java 17 Docker Wget unzip
sudo apt install -y openjdk-17-jre wget unzip

sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker -q
sudo systemctl enable docker
# Añadir Jenkins al grupo Docker (si se utiliza Docker)

sudo usermod -aG docker ubuntu
sudo systemctl restart docker

# Agregar la clave y el repositorio de Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Actualizar repositorios e instalar Jenkins
sudo apt-get update
sudo apt-get install -y jenkins

# Iniciar y habilitar Jenkins
sudo systemctl start jenkins -q
sudo systemctl enable jenkins
sudo usermod -aG docker jenkins
# Verificar el estado de Jenkins
sudo systemctl is-active jenkins

#Instalar Cli aws
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

SERVER=$(hostname -I | awk '{print $1}')
clear
echo "********************************************************************"
echo "**            Continua con la configuracion de Jenkins            **"
echo "el pass es:    $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"
echo "********************************************************************"
echo "**                 Seleccionamos la primera opcion                **"
echo "**                                                                **"
echo "**                    Procedemos a instalar                       **"
echo "**                Coloca los siguientes datos:                    **"
echo "**                       usuario:admin                            **"
echo "**                         pass:admin                             **"
echo "**                        nombre:admin                            **"
echo "**                     mail:admin@test.com                        **"
echo "********************************************************************"
echo "          Generamos el token para acceder a Jenkins"
echo "            http://$SERVER:8080/user/admin/security/"
echo "********************************************************************"
echo "El token debe tener el siguiente nombre:      JENKINS_API_TOKEN"
echo "**  Guarda el token para configurar las credenciales de jenkins   **"
echo "********************************************************************"
read -p "Cuando completes los pasos da click para continuar....."
read -p "Introduce el email de registro de github     " EMAIL_GIT

# 3-5 Cargamos los proyectos que vamos a utilizar
sudo mkdir /var/lib/jenkins/jobs/flappybird-app
cat <<EOF | sudo tee /var/lib/jenkins/jobs/flappybird-app/config.xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1468.vcf4f5ee92395">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@2.2218.v56d0cda_37c72"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@2.2218.v56d0cda_37c72">
      <jobProperties/>
      <triggers/>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
  </actions>
  <description></description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <jenkins.model.BuildDiscarderProperty>
      <strategy class="hudson.tasks.LogRotator">
        <daysToKeep>1</daysToKeep>
        <numToKeep>2</numToKeep>
        <artifactDaysToKeep>-1</artifactDaysToKeep>
        <artifactNumToKeep>-1</artifactNumToKeep>
        <removeLastBuild>false</removeLastBuild>
      </strategy>
    </jenkins.model.BuildDiscarderProperty>
    <org.jenkinsci.plugins.pipeline.modeldefinition.properties.PreserveStashesJobProperty plugin="pipeline-model-definition@2.2218.v56d0cda_37c72">
      <buildCount>2</buildCount>
    </org.jenkinsci.plugins.pipeline.modeldefinition.properties.PreserveStashesJobProperty>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>JENKINS_SERVER</name>
          <defaultValue>$SERVER</defaultValue>
          <trim>false</trim>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3993.v3e20a_37282f8">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.6.0">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/git-ed-hub/flappybird-app.git</url>
          <credentialsId>github</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

sudo mkdir /var/lib/jenkins/jobs/flappybird-deployment
cat <<EOF | sudo tee /var/lib/jenkins/jobs/flappybird-deployment/config.xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1348.v32a_a_f150910e">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@2.2144.v077a_d1928a_40"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@2.2144.v077a_d1928a_40">
      <jobProperties/>
      <triggers/>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
  </actions>
  <description></description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <jenkins.model.BuildDiscarderProperty>
      <strategy class="hudson.tasks.LogRotator">
        <daysToKeep>1</daysToKeep>
        <numToKeep>2</numToKeep>
        <artifactDaysToKeep>-1</artifactDaysToKeep>
        <artifactNumToKeep>-1</artifactNumToKeep>
      </strategy>
    </jenkins.model.BuildDiscarderProperty>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.TextParameterDefinition>
          <name>IMAGE_TAG</name>
          <trim>false</trim>
        </hudson.model.TextParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>EMAIL</name>
          <defaultValue>$EMAIL_GIT</defaultValue>
          <trim>false</trim>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3802.vd42b_fcf00b_a_c">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.2.0">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/git-ed-hub/flappybird-deployment.git</url>
          <credentialsId>github</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <authToken>argocd-token</authToken>
  <disabled>false</disabled>
</flow-definition>
EOF

sudo mkdir /var/lib/jenkins/jobs/aws-eks-deployment
cat <<EOF | sudo tee /var/lib/jenkins/jobs/aws-eks-deployment/config.xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1460.v28178c1ef6e6">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@2.2214.vb_b_34b_2ea_9b_83"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@2.2214.vb_b_34b_2ea_9b_83">
      <jobProperties/>
      <triggers/>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
  </actions>
  <description></description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <jenkins.model.BuildDiscarderProperty>
      <strategy class="hudson.tasks.LogRotator">
        <daysToKeep>-1</daysToKeep>
        <numToKeep>2</numToKeep>
        <artifactDaysToKeep>-1</artifactDaysToKeep>
        <artifactNumToKeep>-1</artifactNumToKeep>
        <removeLastBuild>false</removeLastBuild>
      </strategy>
    </jenkins.model.BuildDiscarderProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3990.vd281dd77a_388">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.6.0">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/git-ed-hub/pipeline_aws_eks_jenkins.git</url>
          <credentialsId>github</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

# Asignarle los permisos para que reconozca los proyectos
sudo chown -R jenkins:jenkins /var/lib/jenkins/jobs/flappybird-app/
sudo chmod -R 755 /var/lib/jenkins/jobs/flappybird-app/
sudo chown -R jenkins:jenkins /var/lib/jenkins/jobs/flappybird-deployment/
sudo chmod -R 755 /var/lib/jenkins/jobs/flappybird-deployment/
sudo chown -R jenkins:jenkins /var/lib/jenkins/jobs/aws-eks-deployment/
sudo chmod -R 755 /var/lib/jenkins/jobs/aws-eks-deployment/

sudo mkdir /var/lib/jenkins/init.groovy.d
cat <<'EOF' | sudo tee /var/lib/jenkins/init.groovy.d/plugins.groovy
import jenkins.model.*
import hudson.PluginManager

def jenkinsInstance = Jenkins.getInstance()
def pluginManager = jenkinsInstance.getPluginManager()

def pluginsToInstall = [
"adoptopenjdk",
"ansible",
"ansicolor",
"ant",
"antisamy-markup-formatter",
"asm-api",
"authentication-tokens",
"aws-credentials",
"aws-java-sdk-api-gateway",
"aws-java-sdk-cloudformation",
"aws-java-sdk-cloudfront",
"aws-java-sdk-codedeploy",
"aws-java-sdk-ec2",
"aws-java-sdk-ecr",
"aws-java-sdk-elasticbeanstalk",
"aws-java-sdk-elasticloadbalancingv2",
"aws-java-sdk-iam",
"aws-java-sdk-lambda",
"aws-java-sdk-minimal",
"aws-java-sdk-organizations",
"aws-java-sdk-sns",
"aws-java-sdk-sqs",
"blueocean-bitbucket-pipeline",
"blueocean-commons",
"blueocean-config",
"blueocean-core-js",
"blueocean-dashboard",
"blueocean-display-url",
"blueocean-events",
"blueocean-git-pipeline",
"blueocean-github-pipeline",
"blueocean-i18n",
"blueocean-jwt",
"blueocean-personalization",
"blueocean-pipeline-api-impl",
"blueocean-pipeline-editor",
"blueocean-pipeline-scm-api",
"blueocean-rest-impl",
"blueocean-rest",
"blueocean-web",
"blueocean",
"bootstrap5-api",
"bouncycastle-api",
"branch-api",
"build-timeout",
"caffeine-api",
"checks-api",
"cloud-stats",
"cloudbees-bitbucket-branch-source",
"cloudbees-folder",
"command-launcher",
"commons-lang3-api",
"commons-text-api",
"config-file-provider",
"configuration-as-code-groovy",
"configuration-as-code",
"credentials-binding",
"credentials",
"dark-theme",
"display-url-api",
"docker-build-publish",
"docker-build-step",
"docker-commons",
"docker-compose-build-step",
"docker-java-api",
"docker-plugin",
"docker-workflow",
"durable-task",
"echarts-api",
"eddsa-api",
"email-ext",
"favorite",
"font-awesome-api",
"git-client",
"git",
"github-api",
"github-branch-source",
"github",
"gradle",
"gson-api",
"handy-uri-templates-2-api",
"htmlpublisher",
"instance-identity",
"ionicons-api",
"jackson2-api",
"jakarta-activation-api",
"jakarta-mail-api",
"javadoc",
"javax-activation-api",
"javax-mail-api",
"jaxb",
"jdk-tool",
"jenkins-design-language",
"jjwt-api",
"job-dsl",
"jobConfigHistory",
"joda-time-api",
"jquery3-api",
"jsch",
"json-api",
"json-path-api",
"junit",
"kubernetes-client-api",
"kubernetes-credentials",
"kubernetes-pipeline-devops-steps",
"kubernetes",
"ldap",
"mailer",
"matrix-auth",
"matrix-project",
"maven-plugin",
"metrics",
"mina-sshd-api-common",
"mina-sshd-api-core",
"okhttp-api",
"pam-auth",
"pipeline-aws",
"pipeline-build-step",
"pipeline-github-lib",
"pipeline-graph-analysis",
"pipeline-graph-view",
"pipeline-groovy-lib",
"pipeline-input-step",
"pipeline-maven-api",
"pipeline-maven",
"pipeline-milestone-step",
"pipeline-model-api",
"pipeline-model-definition",
"pipeline-model-extensions",
"pipeline-rest-api",
"pipeline-stage-step",
"pipeline-stage-tags-metadata",
"pipeline-stage-view",
"plain-credentials",
"plugin-util-api",
"prism-api",
"pubsub-light",
"quality-gates",
"resource-disposer",
"scm-api",
"script-security",
"snakeyaml-api",
"sonar-quality-gates",
"sonar",
"sse-gateway",
"ssh-credentials",
"ssh-slaves",
"sshd",
"structs",
"theme-manager",
"timestamper",
"token-macro",
"trilead-api",
"variant",
"workflow-aggregator",
"workflow-api",
"workflow-basic-steps",
"workflow-cps",
"workflow-durable-task-step",
"workflow-job",
"workflow-multibranch",
"workflow-scm-step",
"workflow-step-api",
"workflow-support",
"ws-cleanup"
]

def installed = pluginManager.plugins.collect { it.shortName }
def toInstall = pluginsToInstall - installed

if (!toInstall.isEmpty()) {
    pluginManager.install(toInstall, true)
    jenkinsInstance.save()
}
EOF
# Asignarle los permisos para que reconozca los archivos
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d
sudo chmod -R 755 /var/lib/jenkins/init.groovy.d

sudo systemctl restart jenkins
clear
echo "************************************************************************************"
echo "**                     Se han cargado las practicas                               **"
echo "**           Configura las credenciales con los siguientes nombres                **"
echo "**      http://$SERVER:8080/manage/credentials/store/system/domain/_/             **"
echo "**             github como user/pass con nombre=github id=github                  **"
echo "**          docker como user/pass con nombre=dockerhub id=dockerhub               **"
echo "**  token jenkins como secret con nombre=JENKINS_API_TOKEN id=JENKINS_API_TOKEN   **"
echo "**            Configura las credenciales de aws para la practica                  **"
echo "**         aws como Aws credentials con nombre=AWS-CREDS id=AWS-CREDS             **"
echo "**                  aws configure --profile NOMBRE_CUENTA                         **"
echo "**                                                                                **"
echo "************************************************************************************"

EOT
~~~

chmod +x install.sh
./install.sh