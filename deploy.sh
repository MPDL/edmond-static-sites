#sudo -u dataverse cp ./*.html /srv/web/payara6/glassfish/domains/domain1/docroot/guides
#sudo -u dataverse cp ./css/*.css /srv/web/payara6/glassfish/domains/domain1/docroot/guides/css
echo ${REPO}
sudo -u dataverse  ls -laR /tmp/${REPO}
