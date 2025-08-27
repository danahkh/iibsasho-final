Cloudflare Pages deployment (Flutter Web)

Follow these steps in Cloudflare Pages to deploy the app and avoid 404:

1) Create/Configure the Pages project
- Source: Connect to Git, repo: iibsasho-final (main)
- Framework preset: None/Other
- Build command: bash scripts/cloudflare_pages_build.sh
- Alternative: npm run build (calls the same script via package.json)
- Build output directory: build/web

2) SPA routing (avoid 404 on refresh/deep links)
- The build script writes build/web/_redirects with: `/*    /index.html   200`
- No extra Pages rule needed.

3) Supabase CORS and auth
- Add your Pages preview and production domains to Supabase CORS origins: https://<project>.pages.dev and your custom domain if used.
- If using Supabase Auth redirect URLs, add the same domains there.

4) Re-deploy
- Trigger a new deployment after saving settings (Deployments → Retry). The build will compile Flutter and publish build/web.

Notes
- Do not set output to `web/` (that’s source, not compiled). Use `build/web` only.
- The script pins Flutter 3.35.1 (Dart >= 3.8) to match pubspec.
