# GAS-Optimizer

[![Validate skill and installers](https://github.com/Deuk1718/GAS-Optimizer/actions/workflows/validate.yml/badge.svg)](https://github.com/Deuk1718/GAS-Optimizer/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Deuk1718/GAS-Optimizer)](https://github.com/Deuk1718/GAS-Optimizer/releases)

GAS-Optimizer는 정적 HTML, SSG, SSR 웹사이트를 **SEO, GEO, AEO, 접근성, 성능, 배포 준비도** 관점에서 분석하고 최적화하는 공개 표준 [Agent Skills](https://agentskills.io/) 패키지입니다.

여기서 GAS는 **GEO · AEO · SEO**를 뜻하며 Google Apps Script와는 관계가 없습니다.

## 핵심 특징

- 6개 품질 영역을 각각 100점으로 평가
- 모든 영역이 개별적으로 95점 이상이어야 통과
- 평균 점수로 부족한 영역을 보완하지 않는 비보상식 게이트
- Critical·High 문제, HTML 검증 오류, 주요 기능 회귀, 허위 구조화 데이터가 있으면 통과 차단
- 측정할 수 없는 필수 항목을 임의로 통과시키지 않고 `[blocked]`로 기록
- Google, Bing, schema.org 및 웹 표준의 공식 자료를 우선 사용
- 크롤링 가능한 초기 HTML과 점진적 향상 원칙 적용
- 분석 승인과 구현 계획 승인을 분리한 2단계 승인
- 최적화 전 백업·체크섬·롤백 계획
- 기능·시각 회귀와 주장·외부 링크·JSON-LD 진실성 검사
- 독립 실행 가능한 동적 HTML 분석 보고서 템플릿 제공

## HTML 분석 보고서 예시

아래 화면은 GAS-Optimizer 워크플로를 실제 **Marketing Education** 프로젝트에 적용해 작성한 `analysis-plan.html` 보고서입니다. 단순 목업이 아니라 초기 분석, 두 단계 승인, 최적화, 검증, 배포 결과까지 기록한 실제 사용 예시입니다.

[![GAS-Optimizer Marketing Education 분석 보고서 미리보기](docs/images/marketing-edu-analysis-report.jpg)](docs/images/marketing-edu-analysis-report.jpg)

보고서는 한 HTML 파일 안에서 다음 정보를 함께 관리합니다.

- 최적화 전·후 6개 영역 점수와 비상쇄형 95점 게이트
- 정적 계측 증거, 평가 기준, 필터 가능한 보완 항목
- 우선순위, 해석상 주의사항, 단계별 실행 계획과 수용 기준
- 파일별 변경 범위, 검증 결과, 백업·롤백 정보
- 분석·계획 승인 기록과 선택형 외부 작업 상태

원본 템플릿은 [`analysis-plan-template.html`](skill/gas-optimizer/assets/analysis-plan-template.html)에 있으며 외부 스타일시트나 JavaScript 없이 단독으로 동작합니다.

## 품질 게이트

아래 여섯 영역이 **모두 95점 이상**이어야 합니다.

1. SEO
2. GEO
3. AEO
4. 접근성
5. 성능
6. 배포 준비도

공통 평가 기준은 [`quality-rubric.md`](skill/gas-optimizer/references/quality-rubric.md)에 있습니다. 프로젝트별 조건을 추가할 수 있지만 공통 기준이나 통과선을 낮출 수는 없습니다.

## 기본 실행 흐름

1. 프로젝트와 렌더링 결과 조사
2. 6개 영역의 증거 기반 분석
3. 동적 `analysis-plan.html` 보고서 생성
4. 사용자에게 분석 승인 요청
5. 파일별 구현·검증·백업 계획 작성
6. 사용자에게 계획 승인 요청
7. 승인 후 백업과 최적화 실행
8. 기능·시각·링크·스키마 회귀 검사
9. 6개 영역을 다시 측정하고 통과할 때까지 반복
10. 품질 게이트 결과와 롤백 방법 보고

## 선택형 확장 기능

다음 기능은 기본적으로 실행되지 않습니다. GAS-Optimizer는 먼저 필요성, 변경 대상, 외부 영향, 되돌리는 방법을 설명하고 사용자가 개별 승인한 항목만 수행합니다.

### 최적화 전에 선택 가능

- Git 버전 관리
- 항목별 전용 증거 원장
- 대규모 사이트 페이지 유형 표본화

### 95점 게이트 통과 후 선택 가능

- Vercel Preview·Production 배포
- Google Search Console 소유권 확인과 사이트맵 제출
- Bing Webmaster Tools 등록과 사이트맵 제출

한 기능의 승인은 다른 외부 작업의 승인을 의미하지 않습니다.

## 공식 지원 환경

| 설치 대상 | 사용하는 환경 | 사용자 설치 위치 | 프로젝트 설치 위치 |
|---|---|---|---|
| `aside` | Aside | `<Aside account root>/skills/user/gas-optimizer` | 지원하지 않음 |
| `claude` | Claude Code | `~/.claude/skills/gas-optimizer` | `.claude/skills/gas-optimizer` |
| `agents` | Codex, Cursor, GitHub Copilot | `~/.agents/skills/gas-optimizer` | `.agents/skills/gas-optimizer` |

macOS, Linux, Windows 설치를 지원합니다. Claude.ai, Claude API, OpenAI API처럼 파일 업로드가 필요한 환경에는 Release의 `gas-optimizer-v1.1.0.zip`을 사용할 수 있습니다.

## 호출 방법

모든 환경에는 두 가지 호출 개념이 있습니다.

1. **자동 호출**: 요청 내용이 스킬 설명과 일치할 때 호스트가 자동으로 선택
2. **명시적 호출**: 사용자가 스킬 이름을 직접 선택하거나 입력

슬래시는 명시적 호출의 한 형태일 뿐이며 환경마다 문법이 다릅니다.

| 환경 | 명시적 호출 |
|---|---|
| Aside | `gas-optimizer 스킬을 사용해서 분석해줘` |
| Claude Code | `/gas-optimizer` |
| Codex CLI·IDE | `$gas-optimizer`, 또는 `/skills`에서 선택 |
| ChatGPT Skills | `@gas-optimizer` 선택 |
| Cursor | `/gas-optimizer` |
| GitHub Copilot | `/gas-optimizer` |
| API | 요청에 skill ID 또는 번들 연결 |

자세한 내용과 자동 호출 예시는 [`docs/INVOCATION.md`](docs/INVOCATION.md)를 참고하십시오.

## 요구 사항

- 지원 대상 Agent Skills 호스트 중 하나
- 전체 워크플로에는 프로젝트 파일 읽기·쓰기와 빌드·검증 명령 실행 기능 필요
- 브라우저, 네트워크, Git, 배포 도구가 없는 환경에서는 해당 검사가 `[blocked]` 또는 수동 단계로 남을 수 있음
- Aside 대상은 Aside를 한 번 실행하여 계정 폴더가 생성되어 있어야 함

## macOS·Linux 설치

```bash
git clone --branch v1.1.0 --depth 1 https://github.com/Deuk1718/GAS-Optimizer.git
cd GAS-Optimizer
chmod +x install.sh uninstall.sh installers/*.sh scripts/build-release.sh
```

사용자 범위 설치:

```bash
./install.sh --target aside --scope user
./install.sh --target claude --scope user
./install.sh --target agents --scope user
./install.sh --target all --scope user
```

프로젝트 범위 설치:

```bash
./install.sh --target agents --scope project --project-root /path/to/project
./install.sh --target claude --scope project --project-root /path/to/project
./install.sh --target all --scope project --project-root /path/to/project
```

`all` 프로젝트 설치는 Claude와 공통 Agent Skills 위치를 설치합니다. Aside는 계정 범위만 지원합니다.

## Windows 설치

PowerShell에서 실행합니다.

```powershell
git clone --branch v1.1.0 --depth 1 https://github.com/Deuk1718/GAS-Optimizer.git
Set-Location GAS-Optimizer
```

사용자 범위 설치:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Target Aside -Scope User
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Target Claude -Scope User
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Target Agents -Scope User
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Target All -Scope User
```

프로젝트 범위 설치:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Target All -Scope Project -ProjectRoot "C:\path\to\project"
```

PowerShell 7에서는 `powershell` 대신 `pwsh`를 사용할 수 있습니다. `-ExecutionPolicy Bypass`는 해당 프로세스에만 적용되며 시스템 정책을 영구 변경하지 않습니다.

## Git 없이 설치

[GitHub Releases](https://github.com/Deuk1718/GAS-Optimizer/releases/latest)에서 Source code 압축 파일을 내려받아 압축을 푼 뒤 위 설치기를 실행합니다.

Claude.ai 또는 API 업로드에는 별도 Release 자산인 다음 파일을 사용합니다.

```text
gas-optimizer-v1.1.0.zip
SHA256SUMS.txt
```

## 설치 동작과 업데이트

설치기는 공통 원본인 `skill/gas-optimizer`를 선택한 위치에 복사합니다. 기존 설치가 있으면 덮어쓰기 전에 자동 백업하며 심볼릭 링크는 교체하지 않습니다.

업데이트는 새 태그를 내려받은 뒤 같은 대상과 범위로 설치기를 다시 실행하면 됩니다. 설치 후 호스트가 즉시 발견하지 못하면 해당 앱이나 세션을 다시 시작하십시오.

## 제거

macOS·Linux:

```bash
./uninstall.sh --target agents --scope user --yes
./uninstall.sh --target all --scope project --project-root /path/to/project --yes
```

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1 -Target Agents -Scope User -Yes
```

제거할 때도 현재 설치본을 먼저 백업합니다.

## 사용 예시

자동 호출을 유도하는 일반 요청:

```text
이 SSR 프로젝트의 SEO, GEO, AEO, 접근성, 성능과 배포 준비도를 각각 평가해줘. 우선 분석만 진행해줘.
```

플랫폼에 관계없이 통하는 명시적 요청:

```text
GAS-Optimizer 스킬을 사용해서 이 프로젝트를 분석해줘. 아직 파일은 수정하지 마.
```

스킬은 먼저 분석 보고서를 만들고 승인을 요청합니다. 명시적으로 호출해도 분석 승인과 계획 승인 단계는 생략되지 않습니다.

## 저장소 구성

```text
GAS-Optimizer/
├── README.md
├── LICENSE
├── VERSION
├── install.sh / install.ps1
├── uninstall.sh / uninstall.ps1
├── installers/
├── scripts/
├── docs/
│   ├── INVOCATION.md
│   └── images/marketing-edu-analysis-report.jpg
├── .github/workflows/
└── skill/gas-optimizer/
    ├── SKILL.md
    ├── references/
    │   ├── quality-rubric.md
    │   └── capability-matrix.md
    └── assets/analysis-plan-template.html
```

## 보안과 한계

- 기존 설치는 덮어쓰기와 제거 전에 자동 백업합니다.
- 심볼릭 링크 또는 예상과 다른 스킬은 자동으로 교체·제거하지 않습니다.
- Release ZIP에는 SHA-256 체크섬을 제공합니다.
- 설치 스크립트를 인터넷에서 바로 파이프로 실행하는 방식은 권장하지 않습니다.
- 호스트가 필요한 도구를 제공하지 않으면 관련 검사는 통과가 아니라 `[blocked]`입니다.
- 점수는 검색 순위, 트래픽, AI 인용 또는 색인 등록을 보장하지 않습니다.
- 실제 배포, GitHub 푸시, Search Console, Bing 등록은 사용자가 선택하고 승인한 경우에만 수행합니다.

## 라이선스

[MIT License](LICENSE)로 공개합니다.

---

**English summary:** GAS-Optimizer is an open-standard Agent Skill for evidence-based SEO, GEO, AEO, accessibility, performance, and deployment-readiness optimization. Each domain must independently score at least 95/100. Aside, Claude Code, Codex, Cursor, and GitHub Copilot installation paths are supported on macOS, Linux, and Windows.
