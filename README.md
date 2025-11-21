# Team 15

Emīls Dzintars, Frederik van der Els, Riya Gupta, Arjun Rajesh Nair, Jimmy Oei, Sneha Prashanth

## Operation Repository

https://github.com/doda25-team15/operation

**Configuration (docker-compose.yml env variables):**

- `GITHUB_ACTOR`: GitHub actor for authentication
- `GITHUB_TOKEN`: GitHub token for authentication

## Model Service (Backend) Repository

https://github.com/doda25-team15/model-service

**Workflows**:

- Release workflow: workflow consisting of two jobs: training the model and releasing the Docker image for the model-service.

**Configuration (Dockerfile env variables):**

- `PORT`: Server port (default: 8081)

**Notes**:

- The service expects the model to be mounted at `/output`, but if not found there, it will download it from GitHub Releases.

## App (Frontend) Repository

https://github.com/doda25-team15/app

**Workflows**:

- Release workflow: releases Docker image for the app service on

**Configuration (Dockerfile env variables):**

- `PORT`: Server port (default: 8080)
- `MODEL_SERVICE_URL`: URL to the model-service endpoint (default: http://localhost:8081)

**Notes**:

- We used Gradle to build the app instead of Maven.

## Lib Repository

https://github.com/doda25-team15/lib-version

**Workflows**:

- Release workflow: builds and releases the library.

**Notes**:

- Uses Gradle instead of Maven.

## Run the application

To run the project make sure Docker is installed. 

You can run the project using docker-compose.yml file. Just go to the operation directory and write the following commands:

```
    echo github_personal_token | docker login ghcr.io -u github_username --password-stdin
    docker compose up
```

make sure to replace github_personal_token and github_username 

## Comments
