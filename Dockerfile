FROM unpatent/docker-truffle
COPY . app
WORKDIR app

CMD ["sh", "test.sh"]
