From compassindocker/rally
ADD scenarios /opt/compass/rally/scenarios
ADD check_health.py /opt/compass/rally/check_health.py
ADD <%= @deployment_name %>/deployment.json /opt/compass/rally/deployment/<%= @deployment_name %>.json
RUN sed 's|#connection=<None>|connection=mysql://rally:rally@"<%= @RALLY_DB %>"/rally|' /etc/rally/rally.conf && \
    rally-manage db recreate && \
    chmod -R go+w /opt/rally/database && \
    sleep 200

