$commitHash = git rev-parse HEAD
$hash = $commitHash.Substring(0, 8) 
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$tag = "${hash}-${timestamp}"

#>
function Dot-Env {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('dotenv')]
    param(
        [ValidateNotNullOrEmpty()]
        [String] $Path = '.env',

        # Determines whether variables are environment variables or normal
        [ValidateSet('Environment', 'Regular')]
        [String] $Type = 'Environment'
    )
    $Env = Get-Content -raw $Path | ConvertFrom-StringData
    $Env.GetEnumerator() | Foreach-Object {
        $Name, $Value = $_.Name, $_.Value
        if ($PSCmdlet.ShouldProcess($Name, "Importing $Type Variable")) {
            switch ($Type) {
                'Environment' { Set-Content -Path "env:\$Name" -Value $Value }
                'Regular' { Set-Variable -Name $Name -Value $Value -Scope Script }
            }
        }
    }
}

dotenv -type Regular

$LOCAL_TAG_NAME="${REGISTRY_NAME}/${IMAGE_NAME}:${tag}"
$CR_IMAGE_TAG="${ACR_NAME}/${LOCAL_TAG_NAME}"
$CR_IMAGE_LATEST="${ACR_NAME}/${REGISTRY_NAME}/${IMAGE_NAME}:latest"

docker build ./ -t $LOCAL_TAG_NAME

docker tag $LOCAL_TAG_NAME $CR_IMAGE_TAG

docker push $CR_IMAGE_TAG
# docker push $CR_IMAGE_LATEST

Write-Output "Creating container app: $CONTAINER_APP_NAME ($CR_IMAGE_TAG)"

az acr login --name $ACR_NAME

az containerapp create `
    --name "$CONTAINER_APP_NAME" `
    --resource-group "$RESOURCE_GROUP" `
    --environment "$CONTAINER_APP_ENVIRONMENT" `
    --image "$CR_IMAGE_TAG" `
    --revision-suffix "$tag" `
    --registry-username "$ACR_USERNAME" `
    --registry-password "$ACR_PASSWORD" `
    --registry-server "$ACR_NAME" `
    --min-replicas "$SCALE_MIN_REPLICAS" `
    --max-replicas "$SCALE_MAX_REPLICAS" `
    --target-port 8443 `
    --env-vars KC_DB=$KC_DB `
KC_DB_URL=$KC_DB_URL `
KC_DB_USERNAME=$KC_DB_USERNAME `
KC_DB_PASSWORD=$KC_DB_PASSWORD `
KC_BOOTSTRAP_ADMIN_USERNAME=$KC_BOOTSTRAP_ADMIN_USERNAME `
KC_BOOTSTRAP_ADMIN_PASSWORD=$KC_BOOTSTRAP_ADMIN_PASSWORD `
    --ingress external `
    --query properties.configuration.ingress.fqdn

if (-not [string]::IsNullOrWhiteSpace($CUSTOM_DOMAIN)) {
    az containerapp hostname add `
    --hostname "$CUSTOM_DOMAIN" `
    --resource-group "$RESOURCE_GROUP" `
    --name "$CONTAINER_APP_NAME"

    az containerapp hostname bind `
        --hostname "$CUSTOM_DOMAIN" `
        --resource-group "$RESOURCE_GROUP" `
        --name "$CONTAINER_APP_NAME" `
        --environment "$CONTAINER_APP_ENVIRONMENT" `
        --validation-method "CNAME"
}
