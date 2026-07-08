# OpenCart Portainer Demo

Ready-to-use OpenCart demo stack for Portainer.

## Run

Deploy `docker-compose.yml` in Portainer after publishing the images from GitHub Actions.

- Storefront: https://demo-oc.ivo.md
- Admin: https://demo-oc.ivo.md/admin
- User: `admin`
- Password: `admin123`

## Reset Demo

Normal redeploys preserve the Docker volumes.

To reset the demo on command, set this stack environment variable in Portainer and redeploy:

```text
OPENCART_RESET_DEMO=1
```

After the reset completes, set it back to:

```text
OPENCART_RESET_DEMO=0
```

## Build Images

Images are built only on command:

1. Open GitHub Actions.
2. Select **Build OpenCart Images**.
3. Click **Run workflow**.

The workflow publishes:

- `ghcr.io/chitzi/ivo-portainer-opencart:latest`
- `ghcr.io/chitzi/ivo-portainer-opencart-dbinit:latest`
