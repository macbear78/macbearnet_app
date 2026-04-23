# Macbear Web

맥베어 홈페이지: **Vue 3 (Vite)** + **Node (Express)** + **MariaDB**. 이후 **AWS Lightsail / Ubuntu 24** 배포를 염두에 둔 구조입니다.

## 구성

- `frontend/` — Vue 3, TypeScript, Vue Router, Vite 개발 서버(프록시로 `/api` → 백엔드)
- `backend/` — Express REST API, `mysql2` 풀
- `sql/schema.sql` — 예시 테이블·시드
- `docker-compose.yml` — 로컬 MariaDB 전용 (선택)

## 요구 사항

- **Node.js 18+** (권장: 20 LTS) — `engines` 필드 참고
- **Docker** — 로컬 DB만 쓸 때
- **MariaDB** — 서버/클라우드에 직접 둘 때 `sql/schema.sql`만 실행

## 로컬 실행

1. **MariaDB** (둘 중 하나)

   ```bash
   cd macbear-web
   docker compose up -d
   mysql -h 127.0.0.1 -P 3306 -u macbear -p macbear < sql/schema.sql
   ```
   (비밀번호: `macbear_dev` — `docker-compose.yml`과 동일)

2. **백엔드**

   ```bash
   cd macbear-web/backend
   cp .env.example .env
   npm install
   npm run dev
   ```

3. **프론트엔드** (다른 터미널)

   ```bash
   cd macbear-web/frontend
   npm install
   npm run dev
   ```

- 프론트: http://127.0.0.1:5173
- API: http://127.0.0.1:3000 (헬스: `/api/health`, 예시: `/api/hello`)

## Lightsail (Ubuntu 24) 배포 시 메모

- Nginx(또는 Caddy)로 정적 `frontend/dist` + `/api` 리버스 프록시
- `systemd`로 Node API 서비스
- MariaDB는 패키지 설치 후 `sql/schema.sql`·DB 유저/비밀번호·`.env`를 서버에 맞게 조정
- `CORS_ORIGIN`에 실제 도메인(HTTPS) 설정
