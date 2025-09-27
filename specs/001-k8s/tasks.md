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
- [x] T012 Create course structure `courses/01-core/` with subdirectories: 01-K8s架构/, 02-核心组件/, 03-应用部署/, labs/
- [x] T013 [P] Write K8s architecture guide `courses/01-core/01-K8s架构/README.md` with component Mermaid diagrams
- [x] T014 [P] Write core components guide `courses/01-core/02-核心组件/README.md` covering Pods, Services, Deployments
- [x] T015 [P] Write application deployment guide `courses/01-core/03-应用部署/README.md` with kubectl examples
- [x] T016 Create Kind cluster setup lab `courses/01-core/labs/kind-cluster.md` with 2-node configuration
- [x] T017 Create nginx deployment lab `courses/01-core/labs/nginx-deployment.md` with resource limits
- [x] T018 [P] Create ConfigMap/Secret lab `courses/01-core/labs/config-management.md` for configuration
- [x] T019 [P] Create core assessment `courses/01-core/assessment/practical.md` deploying multi-tier app

## Phase 3.4: Advanced Production Course (高级生产课程)
- [x] T020 Create course structure `courses/02-advanced/` with subdirectories: 01-生产实践/, 02-监控运维/, 03-安全加固/, labs/
- [x] T021 [P] Write production practices guide `courses/02-advanced/01-生产实践/README.md` with Linux differences
- [x] T022 [P] Write monitoring guide `courses/02-advanced/02-监控运维/README.md` covering Prometheus/Grafana
- [x] T023 [P] Write security guide `courses/02-advanced/03-安全加固/README.md` with RBAC, NetworkPolicy
- [ ] T024 Create monitoring stack lab `courses/02-advanced/labs/prometheus-stack.yaml` with resource optimization
- [ ] T025 Create security hardening lab `courses/02-advanced/labs/security-rbac.yaml` with role definitions
- [ ] T026 [P] Create troubleshooting scenarios `courses/02-advanced/labs/troubleshooting/` with 5 common issues
- [ ] T027 [P] Create advanced assessment `courses/02-advanced/assessment/scenario.yaml` solving production issues

## Phase 3.5: Service Mesh with Istio (服务网格-Istio)
- [ ] T028 Create course structure `courses/03-service-mesh/` with subdirectories: 01-Istio架构/, 02-流量管理/, 03-安全策略/, 04-可观测性/, labs/
- [ ] T029 [P] Write Istio architecture guide `courses/03-service-mesh/01-Istio架构/README.md` with control/data plane diagrams
- [ ] T030 [P] Write traffic management guide `courses/03-service-mesh/02-流量管理/README.md` covering VirtualService, DestinationRule
- [ ] T031 [P] Write security policies guide `courses/03-service-mesh/03-安全策略/README.md` with mTLS, AuthorizationPolicy
- [ ] T032 [P] Write observability guide `courses/03-service-mesh/04-可观测性/README.md` covering metrics, tracing, logging
- [ ] T033 Create Istio installation lab `courses/03-service-mesh/labs/istio-setup.yaml` with resource-optimized profile
- [ ] T034 Create traffic routing lab `courses/03-service-mesh/labs/traffic-management.yaml` with canary deployment
- [ ] T035 [P] Create security lab `courses/03-service-mesh/labs/security-policies.yaml` with mTLS and authorization
- [ ] T036 [P] Create observability lab `courses/03-service-mesh/labs/monitoring-tracing.yaml` with Jaeger and Kiali
- [ ] T037 Create service mesh assessment `courses/03-service-mesh/assessment/mesh-scenario.yaml` with multi-service routing
- [ ] T038 [P] Create Istio troubleshooting guide `courses/03-service-mesh/troubleshooting/README.md` with common issues
- [ ] T039 Create service mesh migration lab `courses/03-service-mesh/labs/mesh-migration.yaml` from vanilla K8s to Istio

## Phase 3.6: Project Implementation - Backend (项目实战-后端)
- [ ] T040 Create Golang backend structure `courses/04-project/golang-backend/` with main.go, handlers/, models/
- [ ] T041 Write Golang REST API `courses/04-project/golang-backend/main.go` with health/ready endpoints
- [ ] T042 [P] Create API handlers `courses/04-project/golang-backend/handlers/api.go` for CRUD operations
- [ ] T043 [P] Create data models `courses/04-project/golang-backend/models/data.go` with validation
- [ ] T044 Write Dockerfile `courses/04-project/golang-backend/Dockerfile` with multi-stage build
- [ ] T045 Create backend K8s manifests `courses/04-project/golang-backend/k8s/deployment.yaml` with 3 replicas

## Phase 3.7: Project Implementation - Frontend (项目实战-前端)
- [ ] T046 [P] Create React frontend structure `courses/04-project/frontend-app/` with src/, public/
- [ ] T047 [P] Write frontend application `courses/04-project/frontend-app/src/App.js` with API integration
- [ ] T048 [P] Create frontend Dockerfile `courses/04-project/frontend-app/Dockerfile` with nginx serving
- [ ] T049 [P] Create frontend K8s manifests `courses/04-project/frontend-app/k8s/deployment.yaml` with 2 replicas

## Phase 3.8: Project Implementation - Gateway (项目实战-网关)
- [ ] T050 Create nginx gateway configuration `courses/04-project/nginx-gateway/nginx.conf` with path routing
- [ ] T051 Create Ingress manifest `courses/04-project/deployment/ingress.yaml` for routing rules
- [ ] T052 [P] Create ConfigMaps `courses/04-project/deployment/configmap.yaml` for application configuration
- [ ] T053 [P] Create Secrets manifest `courses/04-project/deployment/secrets.yaml` for credentials

## Phase 3.9: Validation and Testing Tools (验证测试工具)
- [ ] T054 Create application validation script `tools/validation/test-deployment.sh` checking all components
- [ ] T055 [P] Create performance test script `tools/validation/load-test.sh` with memory monitoring
- [ ] T056 [P] Create cleanup script `tools/troubleshoot/cleanup.sh` for resource management
- [ ] T057 [P] Create backup script `tools/troubleshoot/backup-restore.sh` for data persistence

## Phase 3.10: Documentation and Resources (文档资源)
- [ ] T058 [P] Create kubectl cheatsheet `resources/cheatsheets/kubectl-commands.md` with Chinese explanations
- [ ] T059 [P] Create troubleshooting guide `resources/guides/troubleshooting.md` with common issues
- [ ] T060 [P] Generate architecture diagrams `resources/diagrams/` using Mermaid for all components
- [ ] T061 Create learning progress tracker `resources/progress-tracker.yaml` based on data-model.md
- [ ] T062 Create final validation checklist `resources/validation-checklist.md` ensuring all objectives met

## Task Dependencies

### Critical Path
```
T001 → T006 → T012 → T020 → T028 → T040-T053 → T054
     ↘ T002-T005 (parallel setup)
        ↘ T007-T011 (parallel foundation)
           ↘ T013-T019 (parallel core)
              ↘ T021-T027 (parallel advanced)
                 ↘ T029-T039 (parallel service mesh)
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

**Service Mesh Content (可并行)**:
```bash
# Create Istio learning materials simultaneously
Task T029 "Write Istio architecture guide"
Task T030 "Write traffic management guide"
Task T031 "Write security policies guide"
Task T032 "Write observability guide"
```

**Project Components (可并行)**:
```bash
# Build frontend and backend independently
Task T041-T045 "Backend implementation"
Task T046-T049 "Frontend implementation"
```

## Validation Gates

- **After T005**: Verify Kind cluster can run with memory limits
- **After T011**: Validate foundation learning objectives met
- **After T019**: Ensure core K8s concepts understood
- **After T027**: Confirm production readiness
- **After T039**: Verify service mesh deployment and traffic management
- **After T053**: Test complete application stack with Istio integration
- **After T062**: Final comprehensive validation

## Resource Constraints

All tasks must respect:
- Maximum 20GB memory for entire environment
- Kind cluster: 12GB allocation
- Applications: 4GB allocation
- System overhead: 4GB reserved

## Success Criteria

✓ All 62 tasks completed
✓ Environment runs within 20GB limit (including Istio overhead)
✓ nginx+golang+frontend stack deployed with service mesh
✓ Istio traffic management and security policies functional
✓ All validation scripts passing (including service mesh tests)
✓ Chinese documentation with English terms
✓ Mermaid diagrams in all key documents
✓ Complete service mesh observability stack (Jaeger, Kiali, Prometheus)

---
*Generated from design documents in /specs/001-k8s/*
*Execute with: Run tasks sequentially by phase, parallelize within phases marked [P]*
