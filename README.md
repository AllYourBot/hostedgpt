# HostedGPT

HostedGPT is a free, open-source alternative to ChatGPT. You can run it on your own computer or any server that supports Ruby on Rails, just bring your own OpenAI API key. All the core functionality of ChatGPT is already working (e.g. GPT-3.5 and GPT-4, starting new converstions, streaming responses, asking about attached images, etc). The main thing missing is the mobile app but that's coming soon.

This project is actively looking for contributors to help make it great. The goal is for *every* feature that exists in ChatGPT to exist in this app, then we can start adding lots of new features and extensions beyond what ChatGPT supports.

### Some favorite features of HostedGPT

* **Enjoy chat history, but without your private conversations being used for training!**

  Did you know that all your private, personal past conversations in the left sidebar are allowed to be used for OpenAI training? [Disclosed in this OpenAI article.](https://help.openai.com/en/articles/7730893-data-controls-faq) HostedGPT excludes your history from OpenAI training.
* **Don't commit yourself to $20 per month when you may not use ChatGPT a lot.** You only pay as much as you use!
* **You will never hit the 'You've reached the current usage cap for GPT-4'.** You pay per mesage based on the API rates so you can keep using it as much as you want.

[![](https://img.youtube.com/vi/GuqPne2yl6w/2.jpg)](https://www.youtube.com/watch?v=GuqPne2yl6w)
Watch a demo of the app

# Table of Contents

- [Set Up Live App](#set-up-live-app)
- [Contribute as a Developer](#contribute-as-a-developer)

# Set Up Live App

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

1. Go to your [Render Dashboard](https://dashboard.render.com/)
2. Click "HostedGPT" or whatever you named your Web Service
3. Click "Upgrade" and select $7 per month

## Troubleshooting Render

1. If you encountered an error while waiting for the services to be deployed on Render, click **Dashboard** at the top of the Render screen and click the Service that failed.
2. It should take you to the Events section and the top event should explain the error. It will probably contain a link to click to the **deploy logs**
3. Scroll back up through the logs and find any instances of errors. [Open a new Issue for us](https://github.com/the-dot-bot/hostedgpt/issues/new) and share details.
4. When you are ready to try Render again, it's best to do the following:
5. First, ensure your repo is caught up. Open your fork in github, click the Sync Fork button so that any bug fixes are pulled in.
6. Second, in Render navigate to the Dashboard, Bluebrint, and Env Groups and delete any details associated with **hostedgpt**
7. Now you can go back to your repo and click **Deploy to Render**

# Contribute as a Developer

We welcome contributors! After you get your developoment environment setup, review the list of Issues. We organize the issues into Milestones and are currently working on v0.6. [View 0.6 Milestone](https://github.com/the-dot-bot/hostedgpt/milestone/5). Look for any issues tagged with **Good first issue** and add a comment so we know you're working on it.

## Setting up Development

The easiest way to get up and running is to use the provided docker compose workflow. The only things you need installed on your computer are Docker and Git.

1. Make sure you have [Docker Desktop](https://docs.docker.com/desktop/) installed and running.
2. Clone your fork `git clone [repository url]`
3. `cd` into your clone.
4. Run `docker compose up` to start the app.
5. Open [http://localhost:3000](http://localhost:3000) and register as a new user.
6. Run tests: `docker compose run base rails test`
7. Open the rails console: `docker compose run base rails console`
8. Run a psql console: `docker compose run base psql`

Alternatively, you can set up your development environment locally:

HostedGPT requires these services to be running:

- Postgres ([installation instructions](https://www.postgresql.org/download/))
- Redis ([installation instructions](https://redis.io/download))
- asdf-vm ([installation instructions](https://asdf-vm.com/guide/getting-started.html#_2-download-asdf))

1. `cd ` into your local repository clone
2. `asdf install` to install the correct ruby version
4. `bundle install` to install ruby gems
5. `bin/rails db:setup`  < Note: This will load the sample fixture data into your database
6. `bin/rails dev`  < Starts up all the services
5. Open [http://localhost:3000](http://localhost:3000) and register as a new user.
