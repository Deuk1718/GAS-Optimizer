# 환경별 GAS-Optimizer 호출 방법

Agent Skills 호스트는 보통 두 가지 방식으로 스킬을 선택합니다.

1. **자동 호출**: 사용자의 요청이 `SKILL.md`의 `description`과 일치하면 호스트가 스킬을 선택합니다.
2. **명시적 호출**: 사용자가 스킬 이름을 직접 선택하거나 입력합니다.

슬래시(`/`), 달러 기호(`$`), 앳 기호(`@`)는 모두 명시적 호출의 환경별 문법이며 모든 호스트가 같은 문법을 사용하지는 않습니다.

## 호출 예시

| 환경 | 자동 호출 | 명시적 호출 예시 | 비고 |
|---|---|---|---|
| Aside | 지원 | `gas-optimizer 스킬을 사용해서 이 사이트를 분석해줘` | `/gas-optimizer`는 공식 보장하지 않음 |
| Claude Code | 지원 | `/gas-optimizer 이 프로젝트를 분석해줘` | 스킬 이름을 자연어로 지정해도 됨 |
| Codex CLI·IDE | 지원 | `$gas-optimizer 이 프로젝트를 분석해줘` | `/skills`에서 설치된 스킬 탐색 가능 |
| ChatGPT Skills | 지원 | `@gas-optimizer`를 선택한 뒤 요청 입력 | 설치·연결된 Skills에서 선택 |
| Cursor | 지원 | `/gas-optimizer 이 사이트를 분석해줘` | Agent가 설명을 보고 자동 선택 가능 |
| GitHub Copilot | 지원 | `/gas-optimizer 이 저장소를 분석해줘` | VS Code·Copilot CLI의 Skills 메뉴에서도 선택 가능 |
| Claude.ai | 지원 환경에서 자동 선택 | 업로드한 GAS-Optimizer를 선택하거나 이름을 지정 | 슬래시 호출은 UI 버전에 따라 다를 수 있음 |
| Claude·OpenAI API | 애플리케이션 구현에 따름 | 요청에 skill ID 또는 번들을 연결 | 채팅 명령이 아니라 API 구성으로 호출 |

## 자동 호출용 요청 예시

```text
이 정적 사이트의 SEO, GEO, AEO, 접근성, 성능과 배포 준비도를 각각 평가해줘. 우선 분석만 진행해줘.
```

```text
이 SSR 프로젝트를 비보상식 95점 기준으로 감사하고 동적 분석 보고서를 만들어줘.
```

## 명시적 호출 시 권장 문장

```text
GAS-Optimizer를 사용해서 이 프로젝트를 분석해줘. 아직 파일은 수정하지 말고 1단계 분석 보고서까지만 만들어줘.
```

명시적으로 호출해도 분석 승인과 계획 승인의 두 단계는 생략되지 않습니다.

## 공식 문서

- Agent Skills 표준: https://agentskills.io/specification
- Claude Code Skills: https://code.claude.com/docs/en/skills
- OpenAI Codex Skills: https://developers.openai.com/codex/skills
- Cursor Skills: https://cursor.com/docs/skills
- GitHub Copilot Agent Skills: https://code.visualstudio.com/docs/agent-customization/agent-skills
