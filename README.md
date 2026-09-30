# Terraform + Yandex Cloud + self-hosted Qwen3

Минимальный учебный проект для лекции про Infrastructure as Code и CI/CD.
Terraform создаёт инфраструктуру в Yandex Cloud, `cloud-init` подготавливает одну VM, а GitHub Actions доставляет на неё FastAPI-приложение и выполняет реальный smoke test.

```text
Terraform
   |
   v
Yandex Cloud
   |
   +-- VPC + Subnet + Security Group
   +-- Service Account + Object Storage bucket
   `-- Compute VM (4 vCPU / 8 GB, Ubuntu)
          |
          `-- Docker
                +-- Ollama
                |     `-- qwen3:0.6b
                `-- FastAPI :8000
                       |
                       `-- HTTP внутри Docker network --> Ollama :11434
```

Весь inference выполняется на одной VM. Внешние LLM API не используются, а порт Ollama `11434` не публикуется в интернет.

## Что создаёт Terraform

В каталоге `infra/` находятся явные ресурсы:

- VPC network, subnet и security group;
- Ubuntu VM с отдельным boot disk;
- один service account с ролью `storage.editor`;
- один Object Storage bucket.

Порт `8000` открыт для демонстрационного API. Порт `22` нужен GitHub Actions для доставки приложения по SSH. Bucket показывает managed cloud resource и не участвует в inference.

`cloud-init` используется только при первом запуске VM: устанавливает Docker, запускает официальный контейнер Ollama, ждёт его готовности и выполняет:

```bash
ollama pull qwen3:0.6b
```

Приложение разворачивается позже через CI/CD, а не через `cloud-init`.

## Приложение и модель

FastAPI предоставляет два endpoint:

```http
GET /health
```

```json
{"status":"ok"}
```

```http
POST /sentiment
Content-Type: application/json

{"text":"I love this course"}
```

```json
{"label":"POSITIVE"}
```

Допустимые ответы: `POSITIVE`, `NEGATIVE`, `NEUTRAL`.

Модель `qwen3:0.6b` уже обучена. В проекте нет fine-tuning, training pipeline или Model Registry: Ollama скачивает готовый model artifact и выполняет inference локально.

Важно различать три артефакта:

| Сущность | Что это | Кто с ней работает |
|---|---|---|
| Infrastructure | Terraform configuration и state | Terraform |
| Application | Docker image `sentiment-api:<commit-sha>` | GitHub Actions и Docker |
| Model | `qwen3:0.6b` | Ollama |

## Terraform локально

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Полезные outputs:

```bash
terraform output vm_external_ip
terraform output bucket_name
```

Удаление учебной инфраструктуры:

```bash
terraform destroy
```

## CI/CD

`.github/workflows/ci-cd.yml` содержит один линейный workflow:

```text
validate -> tests -> build -> infra -> deploy -> smoke
```

Для каждого pull request workflow:

1. проверяет формат и валидность Terraform;
2. запускает маленькие unit tests;
3. собирает Docker image приложения с тегом commit SHA.

При push в ветку `main` или ручном запуске с операцией `deploy` workflow дополнительно:

1. восстанавливает учебный локальный Terraform state из GitHub Actions cache;
2. выполняет `terraform plan` и `terraform apply`;
3. получает public IP созданной VM;
4. ждёт SSH и завершения `cloud-init`;
5. передаёт Docker image на VM и запускает FastAPI рядом с Ollama;
6. отправляет реальные positive и negative запросы по пути FastAPI → Ollama → Qwen3.

Модель в CI/CD не обучается и Ollama в smoke test не мокается.

В GitHub откройте **Settings → Secrets and variables → Actions** и добавьте repository secrets:

- `YC_TOKEN`
- `YC_CLOUD_ID`
- `YC_FOLDER_ID`
- `YC_ZONE`
- `YC_BUCKET_NAME`
- `SSH_PUBLIC_KEY`
- `SSH_PRIVATE_KEY`

`SSH_PUBLIC_KEY` должен содержать сам публичный ключ, а не путь к файлу.

Ручной deploy после добавления свежего `YC_TOKEN`:

```bash
gh workflow run ci-cd.yml -f operation=deploy
gh run watch
```

После демонстрации удалите все ресурсы именно этого Terraform-проекта:

```bash
gh workflow run ci-cd.yml -f operation=destroy
gh run watch
```

Cleanup восстанавливает Terraform state из GitHub Actions cache и удаляет VM, disk, network, subnet, security group, service account и bucket. Он намеренно не удаляет посторонние VM из Yandex Cloud folder.

## Что было бы иначе в production

- Terraform state хранился бы в надёжном remote backend с locking, а не в GitHub Actions cache.
- SSH и порт API были бы ограничены доверенными CIDR; внешний API использовал бы TLS и authentication.
- CI использовал бы короткоживущие credentials и Container Registry вместо передачи image archive по SSH.
