CREATE OR REPLACE API INTEGRATION sentry_public_github
    API_PROVIDER=git_https_api
    API_ALLOWED_PREFIXES=('&{ repo }')
    COMMENT = 'Created by Sentry setup script, rev &{ rev }'
    enabled = true;

CREATE OR REPLACE DATABASE sentry_git;

CREATE OR REPLACE GIT REPOSITORY sentry_git.public.sentry_repo
    api_integration = sentry_public_github
    origin = "&{ repo }";

