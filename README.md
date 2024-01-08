# HostedGPT

Do you love using ChatGPT but want more control over your data? Would you like to experiment with new, advanced features that ChatGPT has not implemented yet?

HostedGPT is an open source project that provides all the same baseline functionality as ChatGPT. When you switch from ChatGPT to HostedGPT, you get the same full-featured desktop and mobile app! It's free to use, just bring your own OpenAI API key. And thanks to a community of contributors, HostedGPT has *many* features and extensions that regular ChatGPT does not have yet. And thanks to active development, whenever ChatGPT adds to new features, those same features are quickly added to HostedGPT so that you won't miss out.

### Some favorite features of HostedGPT

* **Enjoy chat history, but without your private conversations being used for training!**

  In ChatGPT, it's quite nice to have a history of your past conversations in the left sidebar so you can easily resume later. This is the default behavior. But did you realize that keeping chat history enabled opts you in to allowing all your private, personal conversations to be used for OpenAI training? [It's explained in this OpenAI article.](https://help.openai.com/en/articles/7730893-data-controls-faq) HostedGPT fixes this: it keeps past conversations but excludes this data from being used by OpenAI training.

## Get Started

1. Click Fork > Create New Fork at the top of this repository
2. Create an account on Render.com and login
2. View your newly created fork within github.com and click the button below.

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

3. When you are taken to Render.com confirm that the title of the page says `You are deploying from a render.yaml file for _____` with your forked repo listed in the blank.
4. Provide a unique Blueprint name such as "hostedgpt-<yourname>".
5. Copy value from the file `config/master.key` and paste it as the value for the RAILS_MASTER_KEY on the page. Then click "Apply".
6. Wait for the hostedgpt database and web service to be deployed. After they are, click "Dashboard" at the top of the Render screen.
7. You should see two "Service Names" called **hostedgpt**, click the one that is of type "Web Service"
8. On the details screen, click the URL that looks something like _hostedgpt-XXX.onrender.com_
