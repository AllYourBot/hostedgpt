![](./public/logo_full_blue.jpg)

# HostedGPT v0.6

HostedGPT is a free, open-source alternative to ChatGPT. It's a Ruby on Rails app so you can run it on any server or even your own computer. Just bring your own OpenAI API key.

This app is designed to be incredibly easy for ChatGPT users to switch. All the features you expect are here plus it supports Claude 3 and GPT-4 in a single app. You can also switch assistants in the middle of a conversation!

This project is led by an experienced rails developer, but I'm actively looking for contributors to help!

## Top features of HostedGPT

- **Your private conversations are not being used for training!**
  ChatGPT uses your private conversations history to train its models. [OpenAI disclosed this in this article](https://help.openai.com/en/articles/7730893-data-controls-faq), and if you disable it then you lose all your conversation history!
- **Use GPT-4 and Claude 3 without two $20 / month subscriptions, you don't even need a single $20 subscription!** You only pay as much as you use. HostedGPT costs nothing so you just pay for your GPT-4 and Claude 3 API usage.
- **A very polished interface with great mobile support** You can "install" on your mobile phone by opening your instance of HostedGPT in your Safari browser, tapping the Share icon, and then selecting "Add to Home Screen".
- **You will never hit the '_You've reached the current usage cap_' errors**.

### Watch a short demo

[![](https://p425.p0.n0.cdn.zight.com/items/qGubwRKr/c4a119a9-254d-454a-b602-610b428ee769.jpg)](https://www.youtube.com/watch?v=hXpNEz-slkU)

## Table of Contents

- [Top features of HostedGPT](#top-features-of-hostedgpt)
  - [Watch a short demo](#watch-a-short-demo)
- [Table of Contents](#table-of-contents)
- [Deploy the app on Render](#deploy-the-app-on-render)
  - [Troubleshooting Render](#troubleshooting-render)
- [Deploy the app on Fly.io](#deploy-the-app-on-flyio)
- [Deploy the app on Heroku](#deploy-the-app-on-heroku)
- [Configure optional features](#configure-optional-features)
  - [Authentication](#authentication)
    - [Password authentication](#password-authentication)
    - [Google OAuth authentication](#google-oauth-authentication)
    - [HTTP header authentication](#http-header-authentication)
- [Contribute as a developer](#contribute-as-a-developer)
  - [Setting up development](#setting-up-development)
    - [Alternatively, you can set up your development environment locally:](#alternatively-you-can-set-up-your-development-environment-locally)
  - [Running tests](#running-tests)
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

1. Click Fork > Create New Fork at the top of this repository. Pull your forked repository down to your computer (the usual git clone ...).
1. Install the Fly command-line tool on Mac with `brew install flyctl` otherwise `curl -L https://fly.io/install.sh | sh` ([view instructions](https://fly.io/docs/hands-on/install-flyctl/))
1. Think of an internal Fly name for your app, it has to be unique to all of Fly, and then in the root directory of the repository you pulled down, run `fly launch --build-only --copy-config --name=APP_NAME_YOU_CHOSE`
  * Say "Yes" when it asks if you want to tweak these settings
1. When it opens your browser, change the Database to `Fly Postgres` with a unique name such as `[APP_NAME]-db` and you can set the configuration to `Development`.
1. Click `Confirm Settings` at the bottom of the page and close the browser.
1. The app will do a bunch of build steps and then return to the command line. Scroll through the output and save the Postgres username & password somewhere as you'll never be able to see those again.
1. Next run `bin/rails db:setup_encryption[true]`. This will initialize some private keys for your app and send them to Fly.
1. Run `fly deploy --ha=false`

1. Assuming you chose `Development` as the DB size in the step above, now you should run `bin/rails db:fly[APP_NAME_FROM_EARLIER,swap,512]` This will increase the swap on your database machine so that it runs a bit better.

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

## Configure optional features

The file `options.yml` contains a number of Features and Settings you can configure. Simple flags are:

- `REGISTRATON_FEATURE` is `true` by default but you can set to `false` to prevent any new people from creating an account.
- `VOICE_FEATURE` - This is an experimental feature to have spoken conversation with your assistant. It's still a bit buggy but it's coming along.

### Authentication

HostedGPT supports multiple authentication methods:

<!-- no toc -->
- [Password authentication](#password-authentication)
- [Google OAuth authentication](#google-oauth-authentication)

#### Password authentication

Password authentication is enabled by default. You can disable it by setting `PASSWORD_AUTHENTICATION_FEATURE` to `false`.

#### Google OAuth authentication

Google OAuth authentication is disabled by default. You can enable it by setting `GOOGLE_AUTHENTICATION_FEATURE` to `true`.

To enable Google OAuth authentication, you need to set up Google OAuth in the Google Cloud Console. It's a bit involved but we've outlined the steps below. After you follow these steps you will set the following environment variables:

- `GOOGLE_AUTH_CLIENT_ID` - Google OAuth client ID (alternatively, you can add `google_auth_client_id` to your Rails credentials file)
- `GOOGLE_AUTH_CLIENT_SECRET` - Google OAuth client secret (alternatively, you can add `google_auth_client_secret` to your Rails credentials file)

**Steps to set up:**

1. **Go to the Google Cloud Console and Create a New Project:**
   - Open your web browser and navigate to [Google Cloud Console](https://console.cloud.google.com/).
   - Click on the project drop-down menu at the top of the page.
   - Select "New Project"
   - Enter a name for your project and click "Create"

2. **Create OAuth Consent Screen:**
   - In the navigation menu, go to "APIs & Services" > "OAuth consent screen"
   - Select "Internal" and click "Create"
   - Fill out the required fields (App name, User support email, etc.).
   - Add your domain (if applicable) and authorized domains.
   - Click "Save and Continue"

3. **Create OAuth Credentials:**
   - In the navigation menu, go to "APIs & Services" > "Credentials"
   - Click on "Create Credentials" and select "OAuth client ID"
   - Choose "Web application" as the application type.
   - Fill out the required fields:
     - **Name:** A descriptive name for your client ID, e.g. "HostedGPT"
     - **Authorized JavaScript origins:** Your application's base URL, e.g., `https://hostedgpt.example.com`
     - **Authorized Redirect URIs:** Add these paths but replace the base URL with yours:
       - `https://hostedgpt.example.com/auth/google/callback`
       - `https://hostedgpt.example.com/auth/gmail/callback`
   - Click "Create"

4. **Set Environment Variables:**
   - After creating the credentials, you will see a dialog with your Client ID and Client Secret.
   - Set the Client ID and Client Secret as environment variables in your application:
     - `GOOGLE_AUTH_CLIENT_ID`: Your Client ID ENV or `google_auth_client_id` in your Rails credentials file
     - `GOOGLE_AUTH_CLIENT_SECRET`: Your Client Secret ENV or `google_auth_client_secret` in your Rails credentials file

#### HTTP header authentication

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

We welcome contributors! After you get your development environment setup, review the list of Issues. We organize the issues into Milestones and are currently working on v0.7. [View 0.7 Milestone](https://github.com/allyourbot/hostedgpt/milestone/6). Look for any issues tagged with **Good first issue** and add a comment so we know you're working on it.

### Setting up development

The easiest way to get up and running is to use the provided docker compose workflow. The only things you need installed on your computer are Docker and Git.

1. Make sure you have [Docker Desktop](https://docs.docker.com/desktop/) installed and running
1. Clone your fork `git clone [repository url]`
1. `cd` into your clone
1. Run `docker compose up --build` to start the app
1. Open [http://localhost:3000](http://localhost:3000) and register as a new user
1. Run tests: `docker compose run base rails test` The app has comprehensive test coverage but note that system tests currently do not work in docker.
1. Open the rails console: `docker compose run base rails console`
1. Run a psql console: `docker compose run base psql`
1. The project root has an `.editorconfig` file to help eliminate whitespace differences in pull requests. It's nice if you install an extension in your IDE to utilize this (e.g. VS Code has "EditorConfig for VS Code").

Every time you pull new changes down, kill docker (if it's running) and re-run:
`docker compose up --build` This will ensure your local app picks up changes to Gemfile, migrations, and docker config.

#### Alternatively, you can set up your development environment locally:

HostedGPT requires these services to be running:

- Postgres ([installation instructions](https://www.postgresql.org/download/))
- rbenv ([installation instructions](https://github.com/rbenv/rbenv))
- ImageMagick (`brew install imagemagick` should work on Mac )

1. `cd` into your local repository clone
1. `rbenv install` to install the correct ruby version (it reads the .ruby-version in the repo)
1. `bin/dev` starts up all the services, installs gems, and inits database (don't run **db:setup** as it will not configure encryption properly)
1. Open [http://localhost:3000](http://localhost:3000) and register as a new user
1. `bin/rails test` and `bin/rails test:system` to run the comprehensive tests
1. The project root has an `.editorconfig` file to help eliminate whitespace differences in pull requests. It's nice if you install an extension in your IDE to utilize this (e.g. VS Code has "EditorConfig for VS Code").

Every time you pull new changes down, kill `bin/dev` and then re-run it. This will ensure your local app picks up changes to Gemfile and migrations.

### Running tests

If you're set up with Docker you run `docker compose run base rails test`. Note that the system tests, which use a headless browser, are not able to run in Docker. They will be run automatically for you if you create a Pull Request against the project.

If you set up the app outside of Docker, then run the usual `bin/rails test` and `bin/rails test:system`.

## Understanding the Docker configuration

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
