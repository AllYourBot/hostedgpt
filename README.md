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

- [Setup the app](#setup-the-app)
- [Contribute as a developer](#contribute-as-a-developer)
- [Changelog](#changelog)

# Setup the app

You can deploy a full version of HostedGPT to the hosting service, Render, for free. This free app works for 90 days and then the database will stop working. You will need to upgrade to a paid version of the database which is $7 / month. Alternatively, you can also run it off your local computer. Jump down to the [Developer Instructions](#contribute-as-a-developer) if you want to run it locally.

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

1. If you encountered an error while waiting for the services to be deployed on Render, click **Dashboard** at the top of the Render screen and click the Service that failed.
2. It should take you to the Events section and the top event should explain the error. It will probably contain a link to click to the **deploy logs**
3. Scroll back up through the logs and find any instances of errors. [Start a new discussion](https://github.com/allyourbot/hostedgpt/discussions/new?category=general) and share details.
4. When you are ready to try Render again, it's best to do the following:
5. First, ensure your repo is caught up. Open your fork in github, click the Sync Fork button so that any bug fixes are pulled in.
6. Second, in Render navigate to the Dashboard, Bluebrint, and Env Groups and delete any details associated with **hostedgpt**
7. Now you can go back to your repo and click **Deploy to Render**

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
- Redis ([installation instructions](https://redis.io/download))
- rbenv or asdf-vm ([installation instructions](https://asdf-vm.com/guide/getting-started.html#_2-download-asdf))

1. `cd` into your local repository clone
2. `rbenv install` or `asdf install` to install the correct ruby version
3. `bin/dev` starts up all the services, installs gems, and inits database (don't run **db:setup** as it will not configure encryption properly)
4. Open [http://localhost:3000](http://localhost:3000) and register as a new user
5. `bin/rails test` and `bin/rails test:system` to run the comprehensive tests

Every time you pull new changes down, kill `bin/dev` and then re-run it. This will ensure your local app picks up changes to Gemfile and migrations.

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
>>>>>>> upstream-main
