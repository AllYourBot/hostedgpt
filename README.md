# HostedGPT

Do you love using ChatGPT but want more control over your data? Would you like to experiment with new, advanced features that ChatGPT has not implemented yet?

HostedGPT is an open source project that provides all the same functionality as ChatGPT \[_that's the goal at least, we aren't there yet!_\]. When you switch from ChatGPT to HostedGPT, you \[_will_\] get the same full-featured desktop and mobile app! It's free to use, just bring your own OpenAI API key. And thanks to a community of contributors, HostedGPT \[_will have_\] *many* features and extensions that regular ChatGPT does not have yet. And thanks to active development, whenever ChatGPT adds to new features, those same features are quickly added to HostedGPT so that you won't miss out.

### Some favorite features of HostedGPT

* **Enjoy chat history, but without your private conversations being used for training!**

  In ChatGPT, it's quite nice to have a history of your past conversations in the left sidebar so you can easily resume later. This is the default behavior. But did you realize that keeping chat history enabled opts you in to allowing all your private, personal conversations to be used for OpenAI training? [It's explained in this OpenAI article.](https://help.openai.com/en/articles/7730893-data-controls-faq) HostedGPT fixes this: it keeps past conversations but excludes this data from being used by OpenAI training.
* **Don't commit yourself to $20 per month when you may not use ChatGPT a lot. You only pay as much as you use!**
* **You will never hit the 'You've reached the current usage cap for GPT-4'.** You pay per mesage based on the API rates so you can keep using it as much as you want.

## Set Up Live App

You can deploy a full version of HostedGPT to the hosting service, Render, for free. This free app works for 90 days and then the database will stop working. You will need to upgrade to a paid version of the database which is $7 / month.

1. Click Fork > Create New Fork at the top of this repository
2. Create an account on Render.com and login
3. View your newly created fork within github.com and click the button below:

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

4. In Blueprint Name, type anything such as "hostedgpt-<yourname>"
5. Click **Apply**
6. Wait for the hostedgpt database and web service to be deployed. The first deploy takes a good 5 minutes so be patient. After they are all deployed, click **Dashboard** at the top of the Render screen. Or if an error occurs, skip to Troubleshooting Render below.
7. You should see two "Service Names" called "hostedgpt-..." (the name you picked), click the one that is of type **Web Service**
8. On the details screen, click the URL that looks something like _hostedgpt-XXX.onrender.com_

## Troubleshooting Render

1. If you encountered an eerror while waiting for the services to be deployed on Render, click **Dashboard** at the top of the Render screen and click the Service that failed.
2. It should take you to the Events section and the top event should explain the error. It will probably contain a link to click to the **deploy logs**
3. Scroll back up through the logs and find any instances of errors. [Open a new Issue for us](https://github.com/hostedgpt/hostedgpt/issues/new) and share details.
4. When you are ready to try Render again, it's best to do the following:
5. First, ensure your repo is caught up. Open your fork in github, click the Sync Fork button so that any bug fixes are pulled in.
6. Second, in Render navigate to the Dashboard, Bluebrint, and Env Groups and delete any details associated with **hostedgpt**
7. Now you can go back to your repo and click **Deploy to Render**

# Contributing

We welcome contributors! After you get your developoment environment setup, review the list of Issues. We organize the issues into Milestones and are currently working on v0.8. [View 0.8 Milestone](https://github.com/hostedgpt/hostedgpt/milestone/3). Look for any issues tagged with **Good first issue**.

## Setting up Development

The easiest way to get up and running is to use the provided docker compose workflow:

1. Make sure you have [Docker Desktop](https://docs.docker.com/desktop/) installed and running.
2. Clone your fork `git clone [repository url]`
3. `cd` into your clone.
4. Run `docker compose up` to start the app.
5. Open [http://localhost:3000](http://localhost:3000) and register as a new user.
6. Run tests: `docker compose run server rails test`
7. Open the rails console: `docker compose run server rails console`
8. Run a psql console: `docker compose run server psql`

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
