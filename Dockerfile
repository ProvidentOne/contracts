FROM unpatent/docker-truffle
COPY . app
WORKDIR app

CMD ["sh", "../scripts/test.sh"]
