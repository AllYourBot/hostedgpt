![](./public/logo_full_blue.jpg)

# HostedGPT v0.6

HostedGPT is a free, open-source alternative to ChatGPT. It's a Ruby on Rails app so you can run it on any server or even your own computer. Just bring your own OpenAI API key.

This app is designed to be incredibly easy for ChatGPT users to switch. All the features you expect are here plus it supports Claude 3 and GPT-4 in a single app. You can also switch assistants in the middle of a conversation!

This project is led by an experienced rails developer, but I'm actively looking for contributors to help!

### Top features of HostedGPT

* **Your private conversations are not being used for training!**
ChatGPT uses your private conversations history to train its models. [OpenAI disclosed this in this article](https://help.openai.com/en/articles/7730893-data-controls-faq), and if you disable it then you lose all your conversation history!
* **Use GPT-4 and Claude 3 without two $20 / month subscriptions, you don't even need a single $20 subscription!** You only pay as much as you use. HostedGPT costs nothing so you just pay for your GPT-4 and Claude 3 API usage.
* **A very polished interface with great mobile support** You can "install" on your mobile phone by opening your instance of HostedGPT in your Safari browser, tapping the Share icon, and then selecting "Add to Home Screen".
* **You will never hit the '*You've reached the current usage cap*' errors**.


### Watch a short demo

[![](https://p425.p0.n0.cdn.zight.com/items/qGubwRKr/c4a119a9-254d-454a-b602-610b428ee769.jpg)](https://www.youtube.com/watch?v=hXpNEz-slkU)


# Table of Contents

- [Deploy the app on Render](#deploy-the-app-on-render)
- [Deploy the app on Fly.io](#deploy-the-app-on-fly)
- [Contribute as a developer](#contribute-as-a-developer)
- [Understanding the Docker configuration](#understanding-the-docker-configuration)
- [Changelog](#changelog)


# Deploy the app on Render

For the easiest way to get started, deploy a full version of HostedGPT to the hosting service, Render, for free. This free app works for 90 days and then the database will stop working. You will need to upgrade to a paid version of the database which is $7 / month. Alternatively, you can also run it off your local computer. Jump down to the [Developer Instructions](#contribute-as-a-developer) if you want to run it locally.

1. Click Fork > Create New Fork at the top of this repository
2. Create an account on Render.com and login. If you are new to Render, you may be prompted to add a credit card to your account. However, you will be on their free plan by default unless you choose to upgrade.
3. View your newly created fork within github.com and click the button below:

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

## Troubleshooting Render

If you encountered an error while waiting for the services to be deployed on Render:

1. Login to your account on Render.com and click **Dashboard** at the top then click the Service that failed.
2. It should take you to the Events section and the top event should explain the error. It will probably contain a link to click to the **deploy logs**
3. Scroll back up through the logs and find any instances of errors. [Start a new discussion](https://github.com/allyourbot/hostedgpt/discussions/new?category=general) and share details.
4. When you are ready to try Render again, it's best to do the following:
5. First, ensure your repo is caught up. Open your fork in github, click the Sync Fork button so that any bug fixes are pulled in.
6. Second, in Render navigate to the Dashboard, Bluebrint, and Env Groups and delete any details associated with **hostedgpt**
7. Now you can go back to your repo and click **Deploy to Render**


# Deploy the app on Fly

Deploying to Fly.io is another great option. It's not quite one-click like Render and it's not 100% free. But we've made the configuration really easy for you and the cost should be about $2 per month, and Render costs $7 per month after 90 days of free servie so Fly is actually less expensive over the long term.

1. Click Fork > Create New Fork at the top of this repository. Pull your forked repository down to your computer (the usual git clone ...).
1. Install the Fly command-line tool [view instructions](https://fly.io/docs/hands-on/install-flyctl/)
3. In the root directory of the repoistory you pulled down, run `fly launch --build-only` and say `Yes` to copy the existing fly.toml, but note that it will generate the wrong settings.
4. **The settings it shows are INCORRECT** so tell it you want to make changes
5. When it opens your browser, change the Database to `Fly Postgres` with a name such as `hostedgpt-db` and you can set the configuration to `Development`.
7. Click `Confirm Settings` at the bottom of the page and close the browser.
8. The app will do a bunch of build steps and then return to the command line. Scroll through the output and save the Postgres username & password somewhere as you'll never be able to see those again.
9. Next run `bin/rails db:setup_encryption[true]`. This will initialize some private keys for your app and send them to Fly.
10. Run `fly deploy`
11. It will automatically deploy 2 servers instead of just 1 so after it finishes deploy run `fly scale count app=1` to scale down to 1 machine.


# Contribute as a developer

We welcome contributors! After you get your developoment environment setup, review the list of Issues. We organize the issues into Milestones and are currently working on v0.7. [View 0.7 Milestone](https://github.com/allyourbot/hostedgpt/milestone/6). Look for any issues tagged with **Good first issue** and add a comment so we know you're working on it.

## Setting up development

The easiest way to get up and running is to use the provided docker compose workflow. The only things you need installed on your computer are Docker and Git.

1. Make sure you have [Docker Desktop](https://docs.docker.com/desktop/) installed and running
2. Clone your fork `git clone [repository url]`
3. `cd` into your clone
4. Run `docker compose up --build` to start the app
5. Open [http://localhost:3000](http://localhost:3000) and register as a new user
6. Run tests: `docker compose run base rails test` The app has comprehensive test coverage but note that system tests currently do not work in docker.
7. Open the rails console: `docker compose run base rails console`
8. Run a psql console: `docker compose run base psql`

Every time you pull new changes down, kill docker (if it's running) and re-run:
`docker compose up --build` This will ensure your local app picks up changes to Gemfile, migrations, and docker config.

### Alternatively, you can set up your development environment locally:

HostedGPT requires these services to be running:

- Postgres ([installation instructions](https://www.postgresql.org/download/))
- rbenv ([installation instructions](https://github.com/rbenv/rbenv))
- ImageMagick (`brew install imagemagick` should work on Mac )

1. `cd` into your local repository clone
2. `rbenv install` or `asdf install` to install the correct ruby version
3. `bin/dev` starts up all the services, installs gems, and inits database (don't run **db:setup** as it will not configure encryption properly)
4. Open [http://localhost:3000](http://localhost:3000) and register as a new user
5. `bin/rails test` and `bin/rails test:system` to run the comprehensive tests

Every time you pull new changes down, kill `bin/dev` and then re-run it. This will ensure your local app picks up changes to Gemfile and migrations.

### Running tests

If you're set up with Docker you run `docker compose run base rails test`. Note that the system tests, which use a headless browser, are not able to run in Docker. They will be run automatically for you if you create a Pull Request against the project.

If you set up the app outside of Docker, then run the usual `bin/rails test` and `bin/rails test:system`.


# Understanding the Docker configuration

The `Dockerfile` is set up to support three distinct situations: development, deploying to Render, and deploying to Fly. Each of these are completely separate targets which don't share any steps, they are simply in the same Dockerfile.

The `docker-compose.yml` is solely for development. It references the `development` build target.

The `render.yml` specifies details of the Render production environment. Note that Render does not support specifying a build target within this file, it simply defaults to the last target with the Dockerfile so the order of the sections within there matter.

The `fly.toml` specifies details of the Fly production environment. It references the `fly-production` build target. The Fly section of the Dockerfile was generated using the dockerfile-rails generator. This is Fly's recommendation and it produces a reasonable production-ready Dockerfile. Edits to this _top section_ of the file have been kept very minimal, on purpose, because it's intended to be updated using the generator. When it was originally generated it saved all the configuration parameters into `config/dockerfile.yml`. When you run `bin/rails generate dockerfile` it will read all these configurations and attempt to re-generate the Dockerfile. You can try this, it will warn you that it's going to overwrite, and press `d` to see the diff of what changes it will make. There should be no functional changes above the line `#### END of FLY ####`. Imagine you wanted to use this generator to change the app to use MySQL ([view all generator options](https://github.com/fly-apps/dockerfile-rails)). You could run `bin/rails generate dockerfile --mysql` and it would update your Gemfile, automatically run bundle install to install any gem changes, and then it will attempt to update Dockerfile where you can again press `d`. Inspect the diff of any changes above the line `#### END of FLY ####` and manually apply those changes. Similarly, view the diff for dockerignore and docker-entrypoint, although none of those changes should be necessary. When you get to `fly.toml` you will want to view that diff closely and manually apply those changes. At the end it will update config/dockerfile.yml to record the new configuration of the Dockerfile. In this way, you can continue to use the generator to keep the Dockerfile updated (as recommended by Fly) while not breaking the dev or Render setup.


# Changelog

(Top features being developed for v0.7: voice support, Gemini Pro, pin conversations)

v0.6 - Released on 4/26/2024

* Abort a long AI reply by clicking stop or simply "interrupting" it with a new question
* Edit your messages and view previous versions with the left & right arrows
* Support PWA (progressive web app) install for mobile phones (open in Safari, tap share then "Add to Home")
* Show a helpful error messages when the API responds with an error
* Re-generate an AI responses and even switch to a different assistant
* Copy-to-clipboard button (and keyboard shortcut) for messages and markdown sections
* Markdown is properly rendered in AI responses (and your own chats)
* Include images in your messages (click icon, drag & drop, or copy & paste into message)

v0.5 - Released on 2/14/2024

* Anthropic's Claude 3 models can be used alongside GPT-4 and GPT-3
* Dark mode theme is now supported (it switches automatically with your OS)
* Full keyboard shortcuts have been added (press ? to see them)
* AI assistants can be given custom instructions (under Profile > Settings)
* Delete conversations
* Ability to edit conversation title
* Conversations are automatically titled
* Sidebar can be closed
* AI responses stream in

1. Go to console.cloud.google.com
2. Create a new organization or select an existing organization
3. Go to the Google API Library and select the services you want to support: https://console.cloud.google.com/apis/library and sel$
3. Go to Credentials / API
4. Create a new Oauth credential
5. Fill out the oAuth consent screen
6. In a new tab go to the Google API li
7. On the next screen, Scopes, add a bunch of permissions
8. Add your test users
9. Go back to API & Services > Credentials (https://console.cloud.google.com/apis/credentials?project=hosted-423518)
10. Click to Create Credentials > OAuth client ID

# be sure to add the different email addresses you want to test
# be sure to get the callback URL correctly
