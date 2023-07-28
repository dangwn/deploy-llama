FROM python:3.9

ARG API_PORT
ARG API_HOST

ENV API_PORT=${API_PORT}
ENV API_HOST=${API_HOST}

COPY . .

RUN pip install --upgrade pip
RUN pip install --default-timeout=900 -r requirements.txt --user

EXPOSE ${API_PORT}

RUN chmod 777 app.sh

CMD [ "./app.sh" ]