# Contributing to HostedGPT

We welcome contributors! After you get your development environment setup, review the list of Issues. We organize the issues into Milestones and are currently wrapping up [v0.7](https://github.com/allyourbot/hostedgpt/milestone/6) and starting 0.8 [View 0.8 Milestone](https://github.com/allyourbot/hostedgpt/milestone/8). Look for any issues tagged with **Good first issue** and add a comment so we know you're working on it.

Get your development environment set up by running the Rails app directly on your machine either with Docker or outside of Docker. See [Running locally on your computer](https://github.com/allyourbot/hostedgpt/blob/main/README.md#running-locally-on-your-computer) for more details.

### Running the test suite

If you're set up with Docker you run `docker compose run base rails test`. Note that the system tests, which use a headless browser, are not able to run in Docker. They will be run automatically for you if you create a Pull Request against the project.

If you set up the app outside of Docker, then run the usual `bin/rails test` and `bin/rails test:system`.

### Understanding the Docker configuration

The `Dockerfile` is set up to support three distinct situations: development, deploying to Render, and deploying to Fly. Each of these are completely separate targets which don't share any steps, they are simply in the same Dockerfile.

The `docker-compose.yml` is solely for development. It references the `development` build target.

The `render.yml` specifies details of the Render production environment. Note that Render does not support specifying a build target within this file, it simply defaults to the last target with the Dockerfile so the order of the sections within there matter.

The `fly.toml` specifies details of the Fly production environment. It references the `fly-production` build target. The Fly section of the Dockerfile was generated using the dockerfile-rails generator. This is Fly's recommendation and it produces a reasonable production-ready Dockerfile. Edits to this _top section_ of the file have been kept very minimal, on purpose, because it's intended to be updated using the generator. When it was originally generated it saved all the configuration parameters into `config/dockerfile.yml`. When you run `bin/rails generate dockerfile` it will read all these configurations and attempt to re-generate the Dockerfile. You can try this, it will warn you that it's going to overwrite, and press `d` to see the diff of what changes it will make. There should be no functional changes above the line `#### END of FLY ####`. Imagine you wanted to use this generator to change the app to use MySQL ([view all generator options](https://github.com/fly-apps/dockerfile-rails)). You could run `bin/rails generate dockerfile --mysql` and it would update your Gemfile, automatically run bundle install to install any gem changes, and then it will attempt to update Dockerfile where you can again press `d`. Inspect the diff of any changes above the line `#### END of FLY ####` and manually apply those changes. Similarly, view the diff for dockerignore and docker-entrypoint, although none of those changes should be necessary. When you get to `fly.toml` you will want to view that diff closely and manually apply those changes. At the end it will update config/dockerfile.yml to record the new configuration of the Dockerfile. In this way, you can continue to use the generator to keep the Dockerfile updated (as recommended by Fly) while not breaking the dev or Render setup.
