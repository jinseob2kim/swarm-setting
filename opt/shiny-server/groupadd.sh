## Add PATH: groupadd & usermod
PATH=$PATH:/usr/sbin/

## Add group: shiny-apps
sudo groupadd shiny-apps && \
sudo usermod -aG shiny-apps rstudio && \
sudo usermod -aG shiny-apps shiny && \

## Chown
cd /home/rstudio/ShinyApps && \
sudo chown -R rstudio:shiny-apps . && \
sudo chmod g+w . && \
sudo chmod g+s .