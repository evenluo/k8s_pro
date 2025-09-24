# Tasks: Kubernetes Expert Learning Curriculum

**Input**: Design documents from `/specs/001-k8s/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/, quickstart.md

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Found: Educational curriculum with Docker Desktop, Kind, kubectl
   → Structure: courses/, tools/, resources/ directories
2. Load optional design documents:
   → data-model.md: 6 entities (Course, Module, Lab, Assessment, Progress, Learner)
   → contracts/: 2 validation contracts, 1 deployment spec
   → research.md: Kind cluster, resource optimization, Chinese content
   → quickstart.md: 4-step validation process
3. Generate tasks by category:
   → Setup: environment, project structure, tools
   → Content: course materials, labs, assessments
   → Tools: validation scripts, deployment configs
   → Application: nginx+golang+frontend stack
   → Documentation: guides, references
4. Apply task rules:
   → Different directories = mark [P] for parallel
   → Prerequisites enforced in sequence
   → Validation after each major phase
5. Number tasks sequentially (T001-T050)
6. Generate dependency notes
7. Create parallel execution guidance
8. Validate task completeness:
   → All courses have modules? ✓
   → All modules have labs? ✓
   → All contracts validated? ✓
9. Return: SUCCESS (50 tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
Educational project structure per plan.md:
- **Courses**: `courses/00-foundation/`, `courses/01-core/`, etc.
- **Tools**: `tools/setup/`, `tools/validation/`, `tools/troubleshoot/`
- **Resources**: `resources/cheatsheets/`, `resources/diagrams/`
- **Application**: `courses/03-project/nginx-gateway/`, etc.

## Phase 3.1: Environment Setup (基础环境配置)
- [x] T001 Create main project directory structure: courses/, tools/, resources/, specs/
- [x] T002 [P] Create setup script `tools/setup/install-dependencies.sh` for macOS with Homebrew
- [x] T003 [P] Create environment validation script `tools/validation/check-environment.sh` based on contracts/environment-validation.yaml
- [x] T004 [P] Create Docker Desktop configuration guide `resources/guides/docker-setup.md` with 8GB memory allocation
- [x] T005 Create Kind cluster configuration `tools/setup/kind-config.yaml` for 3-node cluster within 20GB limit

## Phase 3.2: Foundation Course Materials (基础课程内容)
- [x] T006 Create course structure `courses/00-foundation/` with subdirectories: 01-环境搭建/, 02-容器基础/, 03-Docker入门/, labs/
- [x] T007 [P] Write environment setup guide `courses/00-foundation/01-环境搭建/README.md` with Mermaid diagrams
- [x] T008 [P] Write container concepts guide `courses/00-foundation/02-容器基础/README.md` comparing containers vs VMs
- [x] T009 [P] Write Docker basics tutorial `courses/00-foundation/03-Docker入门/README.md` with hands-on examples
- [x] T010 Create Docker lab exercises `courses/00-foundation/labs/docker-basics.yaml` with validation scripts
- [x] T011 [P] Create foundation assessment quiz `courses/00-foundation/assessment/quiz.json` testing concepts

## Phase 3.3: Core Kubernetes Course (核心K8s课程)
- [ ] T012 Create course structure `courses/01-core/` with subdirectories: 01-K8s架构/, 02-核心组件/, 03-应用部署/, labs/
- [ ] T013 [P] Write K8s architecture guide `courses/01-core/01-K8s架构/README.md` with component Mermaid diagrams
- [ ] T014 [P] Write core components guide `courses/01-core/02-核心组件/README.md` covering Pods, Services, Deployments
- [ ] T015 [P] Write application deployment guide `courses/01-core/03-应用部署/README.md` with kubectl examples
- [ ] T016 Create Kind cluster setup lab `courses/01-core/labs/kind-cluster.yaml` with 2-node configuration
- [ ] T017 Create nginx deployment lab `courses/01-core/labs/nginx-deployment.yaml` with resource limits
- [ ] T018 [P] Create ConfigMap/Secret lab `courses/01-core/labs/config-management.yaml` for configuration
- [ ] T019 [P] Create core assessment `courses/01-core/assessment/practical.yaml` deploying multi-tier app

## Phase 3.4: Advanced Production Course (高级生产课程)
- [ ] T020 Create course structure `courses/02-advanced/` with subdirectories: 01-生产实践/, 02-监控运维/, 03-安全加固/, labs/
- [ ] T021 [P] Write production practices guide `courses/02-advanced/01-生产实践/README.md` with Linux differences
- [ ] T022 [P] Write monitoring guide `courses/02-advanced/02-监控运维/README.md` covering Prometheus/Grafana
- [ ] T023 [P] Write security guide `courses/02-advanced/03-安全加固/README.md` with RBAC, NetworkPolicy
- [ ] T024 Create monitoring stack lab `courses/02-advanced/labs/prometheus-stack.yaml` with resource optimization
- [ ] T025 Create security hardening lab `courses/02-advanced/labs/security-rbac.yaml` with role definitions
- [ ] T026 [P] Create troubleshooting scenarios `courses/02-advanced/labs/troubleshooting/` with 5 common issues
- [ ] T027 [P] Create advanced assessment `courses/02-advanced/assessment/scenario.yaml` solving production issues

## Phase 3.5: Project Implementation - Backend (项目实战-后端)
- [ ] T028 Create Golang backend structure `courses/03-project/golang-backend/` with main.go, handlers/, models/
- [ ] T029 Write Golang REST API `courses/03-project/golang-backend/main.go` with health/ready endpoints
- [ ] T030 [P] Create API handlers `courses/03-project/golang-backend/handlers/api.go` for CRUD operations
- [ ] T031 [P] Create data models `courses/03-project/golang-backend/models/data.go` with validation
- [ ] T032 Write Dockerfile `courses/03-project/golang-backend/Dockerfile` with multi-stage build
- [ ] T033 Create backend K8s manifests `courses/03-project/golang-backend/k8s/deployment.yaml` with 3 replicas

## Phase 3.6: Project Implementation - Frontend (项目实战-前端)
- [ ] T034 [P] Create React frontend structure `courses/03-project/frontend-app/` with src/, public/
- [ ] T035 [P] Write frontend application `courses/03-project/frontend-app/src/App.js` with API integration
- [ ] T036 [P] Create frontend Dockerfile `courses/03-project/frontend-app/Dockerfile` with nginx serving
- [ ] T037 [P] Create frontend K8s manifests `courses/03-project/frontend-app/k8s/deployment.yaml` with 2 replicas

## Phase 3.7: Project Implementation - Gateway (项目实战-网关)
- [ ] T038 Create nginx gateway configuration `courses/03-project/nginx-gateway/nginx.conf` with path routing
- [ ] T039 Create Ingress manifest `courses/03-project/deployment/ingress.yaml` for routing rules
- [ ] T040 [P] Create ConfigMaps `courses/03-project/deployment/configmap.yaml` for application configuration
- [ ] T041 [P] Create Secrets manifest `courses/03-project/deployment/secrets.yaml` for credentials

## Phase 3.8: Validation and Testing Tools (验证测试工具)
- [ ] T042 Create application validation script `tools/validation/test-deployment.sh` checking all components
- [ ] T043 [P] Create performance test script `tools/validation/load-test.sh` with memory monitoring
- [ ] T044 [P] Create cleanup script `tools/troubleshoot/cleanup.sh` for resource management
- [ ] T045 [P] Create backup script `tools/troubleshoot/backup-restore.sh` for data persistence

## Phase 3.9: Documentation and Resources (文档资源)
- [ ] T046 [P] Create kubectl cheatsheet `resources/cheatsheets/kubectl-commands.md` with Chinese explanations
- [ ] T047 [P] Create troubleshooting guide `resources/guides/troubleshooting.md` with common issues
- [ ] T048 [P] Generate architecture diagrams `resources/diagrams/` using Mermaid for all components
- [ ] T049 Create learning progress tracker `resources/progress-tracker.yaml` based on data-model.md
- [ ] T050 Create final validation checklist `resources/validation-checklist.md` ensuring all objectives met

## Task Dependencies

### Critical Path
```
T001 → T006 → T012 → T020 → T028-T041 → T042
     ↘ T002-T005 (parallel setup)
        ↘ T007-T011 (parallel foundation)
           ↘ T013-T019 (parallel core)
              ↘ T021-T027 (parallel advanced)
```

### Parallel Execution Examples

**Setup Phase (可并行)**:
```bash
# Run environment tools in parallel
Task T002 "Create macOS setup script"
Task T003 "Create validation script"
Task T004 "Create Docker guide"
```

**Content Creation (可并行)**:
```bash
# Create course materials simultaneously
Task T007 "Write environment setup guide"
Task T008 "Write container concepts guide"
Task T009 "Write Docker basics tutorial"
```

**Project Components (可并行)**:
```bash
# Build frontend and backend independently
Task T029-T033 "Backend implementation"
Task T034-T037 "Frontend implementation"
```

## Validation Gates

- **After T005**: Verify Kind cluster can run with memory limits
- **After T011**: Validate foundation learning objectives met
- **After T019**: Ensure core K8s concepts understood
- **After T027**: Confirm production readiness
- **After T041**: Test complete application stack
- **After T050**: Final comprehensive validation

## Resource Constraints

All tasks must respect:
- Maximum 20GB memory for entire environment
- Kind cluster: 12GB allocation
- Applications: 4GB allocation
- System overhead: 4GB reserved

## Success Criteria

✓ All 50 tasks completed
✓ Environment runs within 20GB limit
✓ nginx+golang+frontend stack deployed
✓ All validation scripts passing
✓ Chinese documentation with English terms
✓ Mermaid diagrams in all key documents

---
*Generated from design documents in /specs/001-k8s/*
*Execute with: Run tasks sequentially by phase, parallelize within phases marked [P]*