FROM izqui/docker-truffle
COPY . app
WORKDIR app

CMD ["sh", "../scripts/test.sh"]
