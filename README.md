![](./public/logo_full_blue.jpg)

# HostedGPT v0.6

HostedGPT is a free, open-source alternative to ChatGPT. It's a Ruby on Rails app so you can run it on any server or even your own computer. Just bring your own OpenAI API key.

This app is designed to be incredibly easy for ChatGPT users to switch. All the features you expect are here plus it supports Claude 3 and GPT-4 in a single app. You can also switch assistants in the middle of a conversation!

This project is led by an experienced rails developer, but I'm actively looking for contributors to help!

## Top features of HostedGPT

- **Use GPT-4 and Claude 3 without two $20 / month subscriptions, you don't even need a single $20 subscription!** You only pay as much as you use. The HostedGPT app is free so you just pay for your GPT-4 and Claude 3 API usage.
- **A very polished interface with great mobile support** You can "install" on your mobile phone by opening your instance of HostedGPT in your Safari browser, tapping the Share icon, and then selecting "Add to Home Screen".
- **You will never hit the '_You've reached the current usage cap_' errors**.

### Watch a short demo

[![](https://p425.p0.n0.cdn.zight.com/items/qGubwRKr/c4a119a9-254d-454a-b602-610b428ee769.jpg)](https://www.youtube.com/watch?v=hXpNEz-slkU)

## Table of Contents

- [Top features of HostedGPT](#top-features-of-hostedgpt)
  - [Watch a short demo](#watch-a-short-demo)
- [Deploy the app on Render](#deploy-the-app-on-render)
  - [Troubleshooting Render](#troubleshooting-render)
- [Deploy the app on Fly.io](#deploy-the-app-on-flyio)
- [Deploy the app on Heroku](#deploy-the-app-on-heroku)
- [Deploy on your own server](#deploy-on-your-own-server)
- [Running locally on your computer](#running-locally-on-your-computer)
  - [Alternatively, you can run outside of Docker](#alternatively-you-can-run-outside-of-docker)]
- [Configure optional features](#configure-optional-features)
  - [Give assistant access to your Google apps](#configuring-google-tools)
  - [Authentication](#authentication)
    - [Password authentication](#password-authentication)
    - [Google OAuth authentication](#google-oauth-authentication)
    - [Microsoft Graph OAuth authentication](#microsoft-graph-oauth-authentication)
    - [HTTP header authentication](#http-header-authentication)
- [Contribute as a developer](#contribute-as-a-developer)
  - [Running the test suite](#running-the-test-suite)
  - [Understanding the Docker configuration](#understanding-the-docker-configuration)
- [Changelog](#changelog)

## Deploy the app on Render

For the easiest way to get started, deploy a full version of HostedGPT to the hosting service, Render, for free. This free app works for 90 days and then the database will stop working. You will need to upgrade to a paid version of the database which is $7 / month. Alternatively, you can also run it off your local computer. Jump down to the [Developer Instructions](#contribute-as-a-developer) if you want to run it locally.

1. Click Fork > Create New Fork at the top of this repository
2. Create an account on Render.com and login. If you are new to Render, you may be prompted to add a credit card to your account. However, you will be on their free plan by default unless you choose to upgrade.
3. View your newly created fork within github.com and click the button below (be sure you're viewing your fork of this repo before clicking):

   [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

4. In Blueprint Name, type anything such as "hostedgpt-<yourname>"
5. Click **Apply**
6. Wait for the hostedgpt database and web service to be deployed. The first deploy takes a good 5 minutes so be patient. After they are all deployed, click **Dashboard** at the top of the Render screen. Or if an error occurs, skip to Troubleshooting Render below.
7. You should see two "Service Names" called "hostedgpt-..." (the name you picked), click the one that is of type **Web Service**
8. On the details screen, click the URL that looks something like _hostedgpt-XXX.onrender.com_

**NOTE: After 15 minutes of not using the app your Render server will pause. Next time you visit the first request will auto-resume the server, but this resume is slow. If this annoys you, upgrade Render for $7 per month:**

1. To upgrade, go to your [Render Dashboard](https://dashboard.render.com/)
2. Click "HostedGPT" or whatever you named your Web Service
3. Click "Upgrade" and select $7 per month

You may want to read about [configuring optional features](#configure-optional-features).

### Troubleshooting Render

If you encountered an error while waiting for the services to be deployed on Render:

1. Login to your account on Render.com and click **Dashboard** at the top then click the Service that failed.
2. It should take you to the Events section and the top event should explain the error. It will probably contain a link to click to the **deploy logs**
3. Scroll back up through the logs and find any instances of errors. [Start a new discussion](https://github.com/allyourbot/hostedgpt/discussions/new?category=general) and share details.
4. When you are ready to try Render again, it's best to do the following:
5. First, ensure your repo is caught up. Open your fork in github, click the Sync Fork button so that any bug fixes are pulled in.
6. Second, in Render navigate to the Dashboard, Bluebrint, and Env Groups and delete any details associated with **hostedgpt**
7. Now you can go back to your repo and click **Deploy to Render**

## Deploy the app on Fly.io

Deploying to Fly.io is another great option. It's not quite one-click like Render and it's not 100% free. But we've made the configuration really easy for you and the cost should be about $2 per month, and Render costs $7 per month after 90 days of free service so Fly is actually less expensive over the long term.

1. Click Fork > Create New Fork at the top of this repository. **Pull your forked repository down to your computer (the usual git clone ...)**.
1. Go into the directory you just created with your git clone and run `bundle`
1. Install the Fly command-line tool on Mac with `brew install flyctl` otherwise `curl -L https://fly.io/install.sh | sh` ([view instructions](https://fly.io/docs/hands-on/install-flyctl/))
1. Think of an internal Fly name for your app, it has to be unique to all of Fly. You'll use this **APP_NAME** three times in the steps below. First, in the root directory of the repository you pulled down, run `fly launch --build-only --copy-config --name=APP_NAME`

   - Say "Yes" when it asks if you want to tweak these settings

1. When it opens your browser, (i) change the Database to `Fly Automated Postgres`, (ii) set the name to be `[APP_NAME]-db`, (iii) and you can set the configuration to `Development`.
1. Click `Confirm Settings` at the bottom of the page and close the browser.
1. The app will do a bunch of build steps and then return to the command line. Scroll through the output and **save the Postgres username & password somewhere as you'll never be able to see those again**.
1. Next run `bin/rails db:setup_encryption[true]`. This will initialize some private keys for your app and send them to Fly. (If you get an error you may have forgotten to run `bundle`).
1. Run `fly deploy --ha=false`
1. Assuming you chose `Development` as the DB size in the step above, now you should run `bin/rails db:fly[APP_NAME,swap,512]` This will increase the swap on your database machine so that it doesn't crash since the Development database has less ram.

You may want to read about [configuring optional features](#configure-optional-features).

## Deploy the app on Heroku

Heroku is a one-click option that will cost $10/month for the compute (dyno) and database. By default, apps use Eco dynos ($5) if you are subscribed to Eco. Otherwise, it defaults to Basic dynos ($7). The Eco dynos plan is shared across all Eco dynos in your account and is recommended if you plan on deploying many small apps to Heroku. Eco dynos "sleep" after 30 minutes of inactivity and take a few seconds to wake up. Basic dynos do not sleep.

Eligible students can apply for Heroku platform credits through [Heroku for GitHub Students program](https://blog.heroku.com/github-student-developer-program).

1. Click Fork > Create New Fork at the top of this repository
1. Sign up for a free Heroku account at [heroku.com](https://signup.heroku.com/)
1. If you wish to Eco dynos, you will need to subscribe to the $5 Eco dyno plan at [the billing page](https://dashboard.heroku.com/account/billing).
1. View your newly created fork within github.com and click the button below (be sure you're viewing your fork of this repo before clicking):

   [![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://www.heroku.com/deploy)

You may want to read about [configuring optional features](#configure-optional-features).

## Deploy on your own server

There are only two services that need to be running for this app to work: the Puma web server and a Postgres database.

First, ensure your Postgres server is running and verify your connection string using `psql`, for example:

Example:
```
psql postgres://app:secret@postgres/hostedgpt_production
```

Take this DB connection string and start your rails server like this:

```
RAILS_ENV=production RUN_SOLID_QUEUE_IN_PUMA=true DATABASE_URL=postgres://string-you-verified-above rails s -p 8081
```

**Note:** You can change the port 8081 to anything you want.

If you are running a proxy such as nginx, be aware that the app is running http and websockets (ws). Here is an example of what your configuration might look like in order to proxy both of those:

```
<VirtualHost *:443>
  ServerName chat.${maindomain}
  ServerAlias chat.${secondarydomain}
  ProxyPreserveHost On
  ProxyPass / http://localhost:8081/
  ProxyPassReverse / http://localhost:8081/
  RequestHeader set X-Forwarded-Proto "https"
  <Location /cable>
    ProxyPreserveHost On
    ProxyPass ws://localhost:8081/cable
    ProxyPassReverse ws://localhost:8081/cable
  </Location>

  Include /etc/letsencrypt/options-ssl-apache.conf
  SSLCertificateFile /etc/letsencrypt/live/chat.${maindomain}/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/chat.${maindomain}/privkey.pem
</VirtualHost>
```

## Running locally on your computer

The easiest way to get up and running is to use the provided Docker compose workflow. The only things you need installed on your computer are Docker and Git.

1. Make sure you have [Docker Desktop](https://docs.docker.com/desktop/) installed and running
1. Clone your fork `git clone [repository url]`
1. `cd` into your clone
1. Run `docker compose up --build` to start the app
1. Open [http://localhost:3000](http://localhost:3000) and register as a new user
1. Run tests: `docker compose run base rails test` The app has comprehensive test coverage but note that system tests currently do not work in docker.
1. Open the rails console: `docker compose run base rails console`
1. Run a psql console: `docker compose run base psql`
1. If you want a few fake users and a bunch of conversations and other data pre-populated in the database, you can load fixtures into the development database. This can be helpful, for example, if you want to test a migration and save yourself the time manually creating a bunch of data: `docker compose run base rails db:fixtures:load`
1. The project root has an `.editorconfig` file to help eliminate whitespace differences in pull requests. It's nice if you install an extension in your IDE to utilize this (e.g. VS Code has "EditorConfig for VS Code").

Every time you pull new changes down, kill docker (if it's running) and re-run:
`docker compose up --build` This will ensure your local app picks up changes to Gemfile, migrations, and docker config.

If you are doing development see [Running the test suite](#running-the-test-suite).

If you need to make changes to the Docker configuration, see the [Understanding the Docker configuration](#understanding-the-docker-configuration).

If you want to run your LLM locally so the app has no online dependencies, see [Running an LLM on your computer](https://github.com/AllYourBot/hostedgpt/discussions/471).

### Using "Just"

If you have ths `just` tool installed, there are a couple of easy tasks that have been configured for you to start and debug the application:

- `just start` will start the application, this is the best way if you start from 0
- `just bash` will give you a bash console inside the running Rails Docker container
- `just overmind` will give you a access to Overmind which you can use to attach to e.g. the worker
- `just teardown` this will remove everything (sometimes this is great to start from scratch if there are Docker related issues)


### Alternatively, you can run outside of Docker

HostedGPT requires these services to be running:

- Postgres (`brew install postgresql@16` or other [install instructions](https://www.postgresql.org/download/))
- rbenv ([installation instructions](https://github.com/rbenv/rbenv))
- ImageMagick (`brew install imagemagick` should work on Mac )

1. `cd` into your local repository clone
1. `rbenv install` to install the correct ruby version (it reads the .ruby-version in the repo)
1. Do NOT run db:setup as it will not configure encryption properly. Proceed to the next step and it will automatically configure the database.
1. `bin/dev` starts up all the services, installs gems, and handles db. The app will automatically configure a database, but check [Configure optional features](#configure-optional-features) if you need to change the default configuration.
1. Open [http://localhost:3000](http://localhost:3000) and register as a new user.
1. `bin/rails test` and `bin/rails test:system` to run the comprehensive tests
1. The project root has an `.editorconfig` file to help eliminate whitespace differences in pull requests. It's nice if you install an extension in your IDE to utilize this (e.g. VS Code has "EditorConfig for VS Code").
1. If you want a few fake users and a bunch of conversations and other data pre-populated in the database, you can load fixtures into the development database. This can be helpful, for example, if you want to test a migration and save yourself the time manually creating a bunch of data: `bin/rails db:fixtures:load`

Every time you pull new changes down, kill `bin/dev` and then re-run it. This will ensure your local app picks up changes to Gemfile and migrations.

If you are doing development see [Running the test suite](#running-the-test-suite).

If you want to run your LLM locally so the app has no online dependencies, see [Running an LLM on your computer](https://github.com/AllYourBot/hostedgpt/discussions/471).

## Configure optional features

There are a number of optional feature flags that can be set and settings that can be configured. All of these can be seen in the file `options.yml`, however each is explained below and can be activated by setting environment variables.

- `APP_URL_HOST` and `APP_URL_PROTOCOL` are blank but you can set these if you are deploying the app with a public domain. For example, set APP_URL_HOST to `example.com` (leave off https) and set APP_URL_PROTOCOL to `https`. If you set one of these then you must set both of these. There is also APP_URL_PORT but this uses the default for `http` or `https` so you do not normally need to set it.
- Database defaults can be changed with `HOSTED_DB_USERNAME`, `HOSTED_DB_PASSWORD`, `HOSTED_DB_HOST`, `HOSTED_DB_PORT`, and `HOSTED_DB_NAME` (note: _development, _test, and/or _production will be appended after DB_NAME based on the environment).
- `REGISTRATON_FEATURE` is `true` by default, but you can set to `false` to prevent any new people from creating an account.
- `DEFAULT_LLM_KEYS` is `false` by default so each user is expected to add LLM API keys to their user settings. Set this to `true` if you want to configure LLM API keys that will be shared by all users. Set one or more of the additional variables in order to use this feature. The app will still check if the user has added their own API keys for any services and will use those instead of the default ones.
  - `DEFAULT_OPENAI_KEY` will be used by the pre-configured OpenAI API Service
  - `DEFAULT_ANTHROPIC_KEY` will be used by the pre-configured Anthropic API Service
  - `DEFAULT_GROQ_KEY` will be used by the pre-configured Groq API Service
- Edit `models.yml` to modify which Language Models are automatically created for new users upon signing up. Any changes to this file will be applied to existing users when `rails models:import` is run, or when `rails db:prepare` is run, or when the server is restarted. If you ever need to export your list of models you can do `rails models:export[tmp/models.json]`
- `CLOUDFLARE_STORAGE_FEATURE` is `false` by default so any files that are uploaded while chatting with your assistant will be stored in postgres. This is recommended for small deployments. Set this to `true` if you would like to store message attachments in Cloudflare's R2 storage (this mimics AWS S3). You must also sign up for Cloudflare. The free tier allows 10 GB of storage. After you sign up, you need to create a new bucket and an API token. The API token should have "Object Read and Write" access to your bucket. Take note of your Access Key ID and your Secret Access Key along with your Account ID. Set the following environment variables:
  - `CLOUDFLARE_ACCOUNT_ID` - Your Cloudflare Account ID
  - `CLOUDFLARE_ACCESS_KEY_ID` - Your Cloudflare Access Key ID
  - `CLOUDFLARE_SECRET_ACCESS_KEY` - Your Cloudflare Secret Access Key
  - `CLOUDFLARE_BUCKET` - The name of the bucket you created
- `GOOGLE_TOOLS_FEATURE` is `false` by default because this feature is still in development. Set this to `true` if you would like to try the experimental feature where your assistant can access your Gmail, Google Tasks, and soon Google Calendar. After enabling, you need to set up Google OAuth and include the apps as part of the consent flow. See [Configure Google Tools](#configuring-google-tools). After this is done, when each user goes to Settings within the app, there will be a button to explicitly connect their account to Gmail, Google Tasks, and/or Google Calendar. Review `gmail.rb` and `google_tasks.rb` in the directory `app/services/toolbox/` to see what capabilities have currently been built.
- `VOICE_FEATURE` is `false` by default. This is an experimental feature to have spoken conversation with your assistant. It's still a bit buggy but it's coming along.
- `PASSWORD_AUTHENTICATION_FEATURE` is `true` by default, see the [Authentication](#authentication) section for more details.
- `GOOGLE_AUTHENTICATION_FEATURE` is `false` by default, see the [Authentication](#authentication) section for more details.
- `HTTP_HEADER_AUTHENTICATION_FEATURE` is `false` by default. If this is set to `true` it automatically disables Password and Google Authentication Features. See the [Authentication](#authentication) section for more details.

### Configuring Google Tools

You first need to follow all the steps in the [Google OAuth instructions](#google-oauth-authentication). The only step that is optional is that you can leave `GOOGLE_AUTHENTICATION_FEATURE` set to false, which means you don't have to enable new users to register with Google. However, following all the steps will also set up Google Auth so you can connect Google Tools to your assistants. After, you complete those steps, here is the additional configuration you need to do in order to enable the Google tools:

1. **Go back to the OAuth Consent Screen:**

   - In the navigation menu, go to "APIs & Services" > "OAuth consent screen" > click Edit App
   - It starts you on "OAuth consent screen" which is already done, at the bottom click "Save and Continue" to advance to "Scopes"
   - Click "Add or Remove Scopes", check "userinfo.email" and then in "Manually add scopes" paste these URLs, one at a time:
     - https://www.googleapis.com/auth/gmail.modify (then click "Add To Table")
     - https://www.googleapis.com/auth/tasks (then click "Add To Table")

2. **Finally, set `GOOGLE_TOOLS_FEATURE` to true**

### Authentication

HostedGPT supports multiple authentication methods:

<!-- no toc -->

- [Password authentication](#password-authentication)
- [Google OAuth authentication](#google-oauth-authentication)
- [Microsoft Graph OAuth authentication](#microsoft-graph-oauth-authentication)

#### Password authentication

Password authentication is enabled by default. You can disable it by setting `PASSWORD_AUTHENTICATION_FEATURE` to `false`.

#### Google OAuth authentication

Google OAuth authentication is disabled by default. You can enable it by setting `GOOGLE_AUTHENTICATION_FEATURE` to `true`.

To enable Google OAuth authentication, you need to set up Google OAuth in the Google Cloud Console. It's a bit involved but we've outlined the steps below. After you follow these steps you will set the following environment variables:

- `GOOGLE_AUTH_CLIENT_ID` - Google OAuth client ID
- `GOOGLE_AUTH_CLIENT_SECRET` - Google OAuth client secret

Alternately, add the following to your encrypted credentials file:

```yaml
google:
  auth_client_id: <your client id>
  auth_client_secret: <your client secret>
```

**Steps to set up:**

1. **Go to the Google Cloud Console and Create a New Project:**

   - Open your web browser and navigate to [Google Cloud Console](https://console.cloud.google.com/).
   - Click on the project drop-down menu at the top of the page.
   - Select "New Project"
   - Enter a name for your project and click "Create"

2. **Create OAuth Consent Screen:**

   - In the navigation menu, go to "APIs & Services" > "OAuth consent screen"
   - If you want to restrict this to users in your Google Workspace, select "Internal". If you want to let people use any Google account, select "External", and then click "Create"
   - Fill out the required fields (App name, User support email, etc.).
   - Add your domain and authorized domains.
   - Click "Save and Continue"
   - Leaves Scopes blank and click "Save and Continue"
   - On the "Test Users" screen you can enter a few email address that you want to test with, then "Save and Continue"

3. **Create OAuth Credentials:**

   - In the navigation menu, go to "APIs & Services" > "Credentials"
   - Click on "Create Credentials" and select "OAuth client ID"
   - Choose "Web application" as the application type.
   - Fill out the required fields:
     - **Name:** A descriptive name for your client ID, e.g. "HostedGPT"
     - **Authorized JavaScript origins:** Your application's base URL, e.g., `https://example.com`
     - **Authorized Redirect URIs:** Add these paths but replace the base URL with yours:
       - `https://example.com/auth/google/callback`
       - `https://example.com/auth/gmail/callback`
   - Click "Create"

4. **Set Environment Variables:**
   - After creating the credentials, you will see a dialog with your Client ID and Client Secret.
   - Set the Client ID and Client Secret as environment variables in your application:
     - `GOOGLE_AUTH_CLIENT_ID`: Your Client ID
     - `GOOGLE_AUTH_CLIENT_SECRET`: Your Client Secret

#### Microsoft Graph OAuth authentication

Microsoft Graph OAuth authentication is disabled by default. You can enable it by setting `MICROSOFT_GRAPH_AUTHENTICATION_FEATURE` to `true`.

To enable Microsoft Graph OAuth authentication, you need to set up Microsoft Graph OAuth in the Microsoft Azure portal. It's a bit involved but we've outlined the steps below. After you follow these steps you will set the following environment variables:

- `MICROSOFT_GRAPH_AUTH_CLIENT_ID` - Microsoft Graph OAuth client ID
- `MICROSOFT_GRAPH_AUTH_CLIENT_SECRET` - Microsoft Graph OAuth client secret
- `MICROSOFT_GRAPH_SCOPE` - Space separated list of scopes to request. This defaults to `openid profile email offline_access user.read mailboxsettings.read`.

Alternately, add the following to your encrypted credentials file:

```yaml
microsoft_graph:
  auth_client_id: <your client id>
  auth_client_secret: <your client secret>
  scope: openid profile email offline_access user.read mailboxsettings.read
```

Users will need to have setup their full name in their Microsoft account before they can use this authentication method, via <https://profile.live.com/>, otherwise they will see a login/registration error like "First name can't be blank and last name can't be blank".

Users can remotely remove the connection between their Microsoft account and HostedGPT by going to <https://account.microsoft.com/privacy/app-access> and clicking "Don't Allow" on the corresponding application. However, this will not sign out the user from HostedGPT until the session expires.

**Steps to set up:**

1. **Go to the Microsoft Azure portal and create a new application:**

   - Navigate to [Register an application](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/CreateApplicationBlade/quickStartType)
   - Give it a name
   - Select the Supported account types
   - Select the Redirect URI for "Web" (e.g., `https://example.com/auth/microsoft/callback` or `http://localhost:3000/auth/microsoft/callback`)
   - Click Register

2. **Create OAuth Credentials:**

   - The client ID ("Application (client) ID") is displayed on the Overview page
   - To generate a client secret, click on "Add a certificate or secret" > "New client secret"
   - Give it a name and pick an expiration date
   - Back on the "Certificates & secrets" page, the new client secret will be listed under "Value"

3. **Set Environment Variables:**
   - Set the Client ID and Client Secret as environment variables in your application:
     - `MICROSOFT_GRAPH_AUTH_CLIENT_ID`: Your Client ID
     - `MICROSOFT_GRAPH_AUTH_CLIENT_SECRET`: Your Client Secret
     - `MICROSOFT_GRAPH_SCOPE` - Space separated list of scopes to request. This defaults to `openid profile email offline_access user.read mailboxsettings.read`.

#### HTTP header authentication

Note: Enabling this automatically disables Password-based and Google-auth based authentication.

HTTP header authentication is an alternative method to authenticate users based on custom HTTP request headers. This method is useful when you have an existing authentication system, and you want to direct users to HostedGPT and have them skip all authentication steps. They'll be taken right into the app and a HostedGPT user account will be created on the fly. This works by having your existing system set custom headers for authenticated users. This may be a Reverse Proxy (e.g., [Traefik](https://doc.traefik.io/traefik/middlewares/http/forwardauth/) or [Caddy](https://caddyserver.com/docs/caddyfile/directives/forward_auth)) or a Zero Trust Network (e.g., [Tailscale](https://tailscale.com/kb/1312/serve#identity-headers)).

**Steps to set up:**

1. **Enable the feature:**

   - Since HTTP header authentication is disabled by default set the environment variable `HTTP_HEADER_AUTHENTICATION_FEATURE` to `true`. This will automatically disable password and Google OAuth authentication methods.

2. **Configure the request headers:**

   - Beware: enabling HTTP header authentication will allow anyone with direct access to the application to impersonate any user by setting the custom headers, if not properly secured. You must ensure that the custom headers are set by a trusted source and are not easily spoofed.
   - Configure your authentication system to set the following request headers when directing users to the HostedGPT app:
   - `HTTP_HEADER_AUTH_EMAIL` - Set this environment variable to the name of the HTTP request header which will contain the user's email address. This defaults to a check for a request header of `X-WEBAUTH-EMAIL` to find the user's email.
   - `HTTP_HEADER_AUTH_NAME` - Set this environment variable to the name of the HTTP request header which will contain the user's full name (first and last). This defaults to a check for a request header of `X-WEBAUTH-NAME` to find the user's full name.
   - `HTTP_HEADER_AUTH_UID` - Set this environment variable to the name of the HTTP request header which will contain the user's identifier (any unique alphanumeric string). This defaults to a check for a request header of `X-WEBAUTH-USER` to find the user's unique ID.

3. **Test the connection:**
   - After you complete the configuration changes above and restart your server, however you direct users to the HostedGPT app you need to be sure that the request headers are present in that initial visit. This will do a find_or_create on the user: so it will register them if they've never been seen and log them in as that user if the information is already present.

## Contribute as a developer

We welcome contributors! After you get your development environment setup, review the list of Issues. We organize the issues into Milestones and are currently wrapping up v0.7 and starting 0.8 [View 0.8 Milestone](https://github.com/allyourbot/hostedgpt/milestone/8). Look for any issues tagged with **Good first issue** and add a comment so we know you're working on it.

Get your development environment set up by running the Rails app directly on your machine either with Docker or outside of Docker. See [Running locally on your computer](#running-locally-on-your-computer) for more details.

### Running the test suite

If you're set up with Docker you run `docker compose run base rails test`. Note that the system tests, which use a headless browser, are not able to run in Docker. They will be run automatically for you if you create a Pull Request against the project.

If you set up the app outside of Docker, then run the usual `bin/rails test` and `bin/rails test:system`.

### Understanding the Docker configuration

The `Dockerfile` is set up to support three distinct situations: development, deploying to Render, and deploying to Fly. Each of these are completely separate targets which don't share any steps, they are simply in the same Dockerfile.

The `docker-compose.yml` is solely for development. It references the `development` build target.

The `render.yml` specifies details of the Render production environment. Note that Render does not support specifying a build target within this file, it simply defaults to the last target with the Dockerfile so the order of the sections within there matter.

The `fly.toml` specifies details of the Fly production environment. It references the `fly-production` build target. The Fly section of the Dockerfile was generated using the dockerfile-rails generator. This is Fly's recommendation and it produces a reasonable production-ready Dockerfile. Edits to this _top section_ of the file have been kept very minimal, on purpose, because it's intended to be updated using the generator. When it was originally generated it saved all the configuration parameters into `config/dockerfile.yml`. When you run `bin/rails generate dockerfile` it will read all these configurations and attempt to re-generate the Dockerfile. You can try this, it will warn you that it's going to overwrite, and press `d` to see the diff of what changes it will make. There should be no functional changes above the line `#### END of FLY ####`. Imagine you wanted to use this generator to change the app to use MySQL ([view all generator options](https://github.com/fly-apps/dockerfile-rails)). You could run `bin/rails generate dockerfile --mysql` and it would update your Gemfile, automatically run bundle install to install any gem changes, and then it will attempt to update Dockerfile where you can again press `d`. Inspect the diff of any changes above the line `#### END of FLY ####` and manually apply those changes. Similarly, view the diff for dockerignore and docker-entrypoint, although none of those changes should be necessary. When you get to `fly.toml` you will want to view that diff closely and manually apply those changes. At the end it will update config/dockerfile.yml to record the new configuration of the Dockerfile. In this way, you can continue to use the generator to keep the Dockerfile updated (as recommended by Fly) while not breaking the dev or Render setup.

## Changelog

(Notable features being developed for v0.7: Heroku deploy, voice support, skills for the AI, Gemini Pro, pin conversations)

v0.6 - Released on 4/26/2024

- Abort a long AI reply by clicking stop or simply "interrupting" it with a new question
- Edit your messages and view previous versions with the left & right arrows
- Support PWA (progressive web app) install for mobile phones (open in Safari, tap share then "Add to Home")
- Show a helpful error messages when the API responds with an error
- Re-generate an AI responses and even switch to a different assistant
- Copy-to-clipboard button (and keyboard shortcut) for messages and markdown sections
- Markdown is properly rendered in AI responses (and your own chats)
- Include images in your messages (click icon, drag & drop, or copy & paste into message)

v0.5 - Released on 2/14/2024

- Anthropic's Claude 3 models can be used alongside GPT-4 and GPT-3
- Dark mode theme is now supported (it switches automatically with your OS)
- Full keyboard shortcuts have been added (press ? to see them)
- AI assistants can be given custom instructions (under Profile > Settings)
- Delete conversations
- Ability to edit conversation title
- Conversations are automatically titled
- Sidebar can be closed
- AI responses stream in
