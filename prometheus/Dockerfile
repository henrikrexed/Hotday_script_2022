FROM hrexed/xk6-dynatrace-output:0.10
COPY --chown=root:root ./loadgenerator.js ./loadgenerator.js
ENTRYPOINT ["k6","run","-o", "output-dynatrace" ,"./loadgenerator.js"]