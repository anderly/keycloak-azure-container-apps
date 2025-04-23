#!/bin/bash

# Get commit hash and create tag
COMMIT_HASH=$(git rev-parse HEAD)
HASH=${COMMIT_HASH:0:8}
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
TAG="${HASH}-${TIMESTAMP}"

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set image tags
LOCAL_TAG_NAME="$REGISTRY_NAME/$IMAGE_NAME:$TAG"
CR_IMAGE_TAG="$ACR_NAME/$LOCAL_TAG_NAME"
CR_IMAGE_LATEST="$ACR_NAME/$REGISTRY_NAME/$IMAGE_NAME:latest"

# Build and push Docker image
docker build ./ -t $LOCAL_TAG_NAME
docker tag $LOCAL_TAG_NAME $CR_IMAGE_TAG
docker push $CR_IMAGE_TAG
# Optionally push latest tag
# docker push $CR_IMAGE_LATEST

echo "Creating container app: $CONTAINER_APP_NAME ($CR_IMAGE_TAG)"

az acr login --name $ACR_NAME

# Create container app
az containerapp create \
    --name "$CONTAINER_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --environment "$CONTAINER_APP_ENVIRONMENT" \
    --image "$CR_IMAGE_TAG" \
    --revision-suffix "$TAG" \
    --registry-username "$ACR_USERNAME" \
    --registry-password "$ACR_PASSWORD" \
    --registry-server "$ACR_NAME" \
    --min-replicas "$SCALE_MIN_REPLICAS" \
    --max-replicas "$SCALE_MAX_REPLICAS" \
    --target-port 8080 \
    --env-vars KC_DB=$KC_DB \
KC_DB_URL=$KC_DB_URL \
KC_DB_USERNAME=$KC_DB_USERNAME \
KC_DB_PASSWORD=$KC_DB_PASSWORD \
KC_BOOTSTRAP_ADMIN_USERNAME=$KC_BOOTSTRAP_ADMIN_USERNAME \
KC_BOOTSTRAP_ADMIN_PASSWORD=$KC_BOOTSTRAP_ADMIN_PASSWORD \
    --ingress external \
    --query properties.configuration.ingress.fqdn

# Only proceed with custom domain configuration if CUSTOM_DOMAIN is set
if [ ! -z "$CUSTOM_DOMAIN" ]; then

# Add custom domain
az containerapp hostname add \
    --hostname "$CUSTOM_DOMAIN" \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_APP_NAME"

# Bind custom domain
az containerapp hostname bind \
    --hostname "$CUSTOM_DOMAIN" \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_APP_NAME" \
    --environment "$CONTAINER_APP_ENVIRONMENT" \
    --validation-method "CNAME" 
