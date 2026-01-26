### Week 1 (Nov 10-16)

- Jimmy:

  Created the organization, repositories and board for the project. Initialized the model-service repository and added a workflow for training the model.

- Emīls:

  pushed project template to app

- Riya:

  Updated the project template to include the frontend in the app repository and the backend in the model-service repository

- Sneha:

  Went through the repositories and ran the existing backend.

### Week 2 (Nov 17-23)

- Jimmy: https://github.com/doda25-team15/model-service/pull/5, https://github.com/doda25-team15/app/pull/4

  Made the listening ports configurable through environment variables in both the model-service and app.

- Arjun: https://github.com/doda25-team15/model-service/pull/1, https://github.com/doda25-team15/model-service/pull/4

  Dockerized the model-service and added automatic model and preprocessor loading via volume mount or GitHub download.

- Frederik: https://github.com/doda25-team15/lib-version/tree/f6a07ef, https://github.com/doda25-team15/app/pull/3

  I created the lib-version project, made it version-aware, and added a dependency on it in the app project.

- Emīls: https://github.com/doda25-team15/app/pull/2

  Added Dockerfile to the frontend

- Riya: https://github.com/doda25-team15/app/pull/1, https://github.com/doda25-team15/model-service/pull/2, https://github.com/doda25-team15/model-service/pull/3

  Created the image release workflow for frontend and backend, including support for multiple architectures in the container images.

- Sneha: https://github.com/doda25-team15/operation/pull/19/commits, https://github.com/doda25-team15/lib-version/pull/1

  Created the docker-compose.yml file in operation repo and raised a PR for advanced versioning

### Week 3 (Nov 24-30)

- Riya: https://github.com/doda25-team15/operation/pull/40, https://github.com/doda25-team15/app/pull/8

  Worked on steps 9-12 as part of assignment 2, updated Dockerfile for the app repository to change from gradle to maven and remove Github variables

- Emīls: updated dockerfiles to use images from ghcr: https://github.com/doda25-team15/model-service/pull/6, https://github.com/doda25-team15/app/pull/9.

  steps 1-4 from assignment 2: https://github.com/doda25-team15/operation/pull/36.

- Jimmy: https://github.com/doda25-team15/operation/pull/49, https://github.com/doda25-team15/operation/pull/50, https://github.com/doda25-team15/model-service/pull/5

  Worked on steps 16-21 and got halfway through step 22.

- Frederik: https://github.com/doda25-team15/app/pull/6, https://github.com/doda25-team15/app/pull/7, https://github.com/doda25-team15/app/pull/11, https://github.com/doda25-team15/operation/pull/64

- Sneha: https://github.com/doda25-team15/lib-version/pull/1 was merged, https://github.com/doda25-team15/operation/pull/48

  Implemented the migration from Gradle to Maven, fixed a bug with the SMS endpoint, migrated the building process from the Dockerfile to the workflow (after first fixing many existing bugs), made image dependencies fixed (no `:latest`).

- Arjun: https://github.com/doda25-team15/operation/pull/37
  Implemented the steps 5-8 from the assignment 2 and did some code reviews.

### Week 4 (Dec 1-7)

- Arjun: https://github.com/doda25-team15/operation/pull/68
  Fixed the error of gaining authorization into Kubernetes Dashboard. Installed Istio (v1.25.2) by downloading it, adding istioctl to PATH, and running the Istio installation for service-mesh support.
- Riya: https://github.com/doda25-team15/operation/pull/69, https://github.com/doda25-team15/model-service/pull/7

  Updated the application to run Kubernetes deployment using minikube and kubectl. Created Helm Chart and its deployment configuration. Worked on feedback received regarding A1 to make the docker images public and separate the workflows.

- Frederik: https://github.com/doda25-team15/model-service/pull/8

  Moved training of model outside `docker run`.

- Sneha: https://github.com/doda25-team15/app/pull/12, https://github.com/doda25-team15/operation/pull/74

- Emīls: https://github.com/doda25-team15/operation/pull/67

  Migrate from Docker Compose to Kubernetes

- Jimmy: https://github.com/doda25-team15/operation/pull/72

  Worked on start of Grafana dashboards.

### Week 5 (Dec 8-14)

- Arjun: https://github.com/doda25-team15/operation/pull/87
  Worked on resolving the warnings which show up when installing helm

- Jimmy: https://github.com/doda25-team15/operation/pull/84, https://github.com/doda25-team15/operation/pull/86

  Fixed the failing model-service pods. Fixed prometheus not picking up metrics from the app. Added a Grafana dashboard for the custom metrics. Simplified the README.md file.

- Riya: https://github.com/doda25-team15/operation/pull/91

  Implemented shadow launch as the additional istio use case.

- Frederik: https://github.com/doda25-team15/operation/pull/96

  Fixed a bug with the spam detection gauge, implemented feedback from Peer.

- Emils: https://github.com/doda25-team15/operation/pull/90, https://github.com/doda25-team15/operation/pull/92

  started working on traffic management and created inventory ini generation

### Week 6 (Dec 15-21)

- Jimmy: https://github.com/doda25-team15/operation/pull/104

  Made a start of the deployment document, created a diagram for the deployment architecture and for the provisioning architecture.

- Riya: https://github.com/doda25-team15/operation/pull/95

  Update traffic management implementation to include canary release for model service.

- Emils: https://github.com/doda25-team15/operation/pull/98, https://github.com/doda25-team15/operation/pull/97

  update stickiness and introduce change to canary to use different app image

- Frederik: https://github.com/doda25-team15/app/pull/13, https://github.com/doda25-team15/operation/pull/107

  I made an endpoint on app for libversion and worked on fixing advanced versioning for libversion.

- Arjun: NO PRs

  Approved and reviewed other's PRs but couldn't get started working on my work because it was dependant on others work.

### Week 7 (Jan 5-11)

- Riya: https://github.com/doda25-team15/operation/pull/117

  Update canary routing for model service and separate model service volume mounts for stable and canary versions.

- Arjun: https://github.com/doda25-team15/operation/pull/116

  Added continuous experimentation to the model service.
- Jimmy: https://github.com/doda25-team15/operation/pull/120

  Improved vagrantfile according to requirements, updated readme file for better clarity and fixed some small bugs.

- Emils: https://github.com/doda25-team15/operation/pull/119

  added sh script to test 90/10 split in the traffic

- Frederik: https://github.com/doda25-team15/lib-version/pull/3

  Fixed advanced versioning scheme by adding custom GitHub App that can push to protected branches.

### Week 8 (Jan 12-18)

- Arjun: https://github.com/doda25-team15/operation/pull/122
Added extension proposal for automated canary deployments with Flagger.

- Jimmy: https://github.com/doda25-team15/operation/pull/123

  Finalized the deployment document and add fault injection toggle to values.yaml and make it disabled by default.

- Frederik: https://github.com/doda25-team15/lib-version/commit/403f7402640f2ab10c208f0c2d37df343549c340

- Riya: https://github.com/doda25-team15/operation/pull/124
  
  Add sections for request flow and external access summary in the deployment document.

### Week 9 (Jan 19-25)

- Arjun: https://github.com/doda25-team15/operation/pull/125
Added simulataneous shadow and canary deployment to model service.

- Jimmy: https://github.com/doda25-team15/operation/pull/128, https://github.com/doda25-team15/operation/pull/131, https://github.com/doda25-team15/lib-version/pull/4

  Updated the deployment document and diagram with prometheus alerting and scraping metrics. Updated lib-version to properly do stable releases for main branch.

- Riya: https://github.com/doda25-team15/operation/pull/129, https://github.com/doda25-team15/app/pull/14
  
  Tested entire implementation for assignment 1. Updated docker compose to include restart policy and updated the README in app repository.

  -Emils: https://github.com/doda25-team15/operation/pull/126

  Added alertrule and connected alerting to stack

### Week 10 (Jan 26-27)

- Frederik: https://github.com/doda25-team15/operation/pull/134

  Finalized A4. Did a bunch of other stuff while doing so.
